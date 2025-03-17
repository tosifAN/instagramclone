package handlers

import (
	"fmt"
	"instagram-backend/cache"
	"instagram-backend/models"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthHandler struct {
	db        *gorm.DB
	rateLimit *time.Ticker
}

func NewAuthHandler(db *gorm.DB) *AuthHandler {
	requestsPerSecond, _ := strconv.Atoi(os.Getenv("RATE_LIMIT_REQUESTS_PER_SECOND"))
	if requestsPerSecond <= 0 {
		requestsPerSecond = 10 // Default value
	}
	return &AuthHandler{
		db:        db,
		rateLimit: time.NewTicker(time.Second / time.Duration(requestsPerSecond)),
	}
}

type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Name     string `json:"name" binding:"required"`
	Role     string `json:"role" binding:"required,oneof=buyer seller"` // "buyer" or "seller"
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// @Summary Register a new user
// @Description Register a new user with the provided information
// @Tags auth
// @Accept json
// @Produce json
// @Param user body RegisterRequest true "User registration information"
// @Success 201 {object} models.SwaggerUser
// @Failure 400 {object} map[string]string
// @Failure 409 {object} map[string]string
// @Failure 429 {object} map[string]string "Rate limit exceeded"
// @Failure 500 {object} map[string]string
// @Router /api/v1/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	// Apply rate limiting
	<-h.rateLimit.C

	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Create channels for parallel processing
	existingUserChan := make(chan error)
	hashedPasswordChan := make(chan []byte)
	errorChan := make(chan error)

	// Check if user exists in parallel
	go func() {
		var existingUser models.User
		result := h.db.Where("email = ? OR username = ?", req.Email, req.Username).First(&existingUser)
		existingUserChan <- result.Error
	}()

	// Hash password in parallel
	go func() {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			errorChan <- err
			return
		}
		hashedPasswordChan <- hashedPassword
	}()

	// Wait for user check
	if err := <-existingUserChan; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "User already exists"})
		return
	}

	// Wait for password hash
	select {
	case err := <-errorChan:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password: " + err.Error()})
		return
	case hashedPassword := <-hashedPasswordChan:
		// Create user with the hashed password
		user := models.User{
			Username: req.Username,
			Email:    req.Email,
			Password: string(hashedPassword),
			Name:     req.Name,
			Role:     req.Role,
		}

		if result := h.db.Create(&user); result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
			return
		}

		// Generate token
		token, err := generateToken(user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"token": token,
			"user":  user,
		})
	}
}

// GetUserSubscribers fetches the list of buyers subscribed to the seller.
func (h *AuthHandler) GetUserSubscribers(c *gin.Context) {
	// Apply rate limiting
	<-h.rateLimit.C

	// Use preloading and indexing for better performance
	var subscribers []models.User
	if err := h.db.Select("DISTINCT users.*").
		Joins("JOIN subscriptions ON users.id = subscriptions.subscriber_id").
		Where("subscriptions.seller_id = ?", c.Param("id")).
		Find(&subscribers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch subscribers"})
		return
	}

	// Set cache headers for better performance
	c.Header("Cache-Control", "private, max-age=300")
	c.JSON(http.StatusOK, subscribers)
}

// @Summary User login
// @Description Authenticate a user and return a JWT token
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body LoginRequest true "Login credentials"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 429 {object} map[string]string "Rate limit exceeded"
// @Failure 500 {object} map[string]string
// @Router /api/v1/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if result := h.db.Where("email = ?", req.Email).First(&user); result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	token, err := generateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	// Cache user data after successful login
	if err := cache.CacheUser(c.Request.Context(), &user); err != nil {
		// Log the error but don't fail the request
		log.Printf("Failed to cache user data: %v", err)
	}

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"user":  user,
	})
}

// @Summary Get user profile
// @Description Get user profile by ID
// @Tags users
// @Accept json
// @Produce json
// @Param id path int true "User ID"
// @Success 200 {object} models.SwaggerUser
// @Failure 404 {object} map[string]string
// @Security BearerAuth
// @Router /api/users/{id} [get]
func (h *AuthHandler) GetUser(c *gin.Context) {
	userID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	// Try to get user from cache first
	cachedUser, err := cache.GetCachedUser(c.Request.Context(), uint(userID))
	if err == nil {
		c.Header("X-Cache", "HIT")
		c.Header("Cache-Control", "private, max-age=300")
		c.JSON(http.StatusOK, cachedUser)
		return
	}

	var user models.User
	if err := h.db.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Cache the user for future requests
	if err := cache.CacheUser(c.Request.Context(), &user); err != nil {
		log.Printf("Failed to cache user: %v", err)
	}

	c.Header("Cache-Control", "private, max-age=300")
	c.JSON(http.StatusOK, user)
}

// @Summary Update user profile
// @Description Update user profile information
// @Tags users
// @Accept json
// @Produce json
// @Param id path int true "User ID"
// @Param user body map[string]interface{} true "User update information"
// @Success 200 {object} models.SwaggerUser
// @Failure 400 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Security BearerAuth
// @Router /api/users/{id} [put]
func (h *AuthHandler) UpdateUser(c *gin.Context) {
	userID := c.GetUint("user_id")
	paramID := c.Param("id")

	var user models.User
	if err := h.db.First(&user, paramID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if user.ID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized to update this user"})
		return
	}

	var updateData struct {
		Name         string `json:"name"`
		Bio          string `json:"bio"`
		ProfileImage string `json:"profileImage"`
	}

	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user.Name = updateData.Name
	user.Bio = updateData.Bio
	user.ProfileImage = updateData.ProfileImage

	if err := h.db.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	// Invalidate the user cache after update
	if err := cache.InvalidateUserCache(c.Request.Context(), user.ID); err != nil {
		log.Printf("Failed to invalidate user cache: %v", err)
	}

	c.JSON(http.StatusOK, user)
}

// GetUserSubscriptions fetches the list of sellers a buyer is subscribed to.
func (h *AuthHandler) GetUserSubscriptions(c *gin.Context) {
	var subscriptions []models.User
	if err := h.db.Joins("JOIN subscriptions ON users.id = subscriptions.seller_id").
		Where("subscriptions.subscriber_id = ?", c.Param("id")).Find(&subscriptions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch subscriptions"})
		return
	}
	c.JSON(http.StatusOK, subscriptions)
}

func generateToken(userOrID interface{}) (string, error) {
	expiryDays, _ := strconv.Atoi(os.Getenv("JWT_EXPIRY_DAYS"))
	if expiryDays <= 0 {
		expiryDays = 7 // Default value
	}

	claims := jwt.MapClaims{
		"exp": time.Now().Add(time.Hour * 24 * time.Duration(expiryDays)).Unix(),
	}

	switch v := userOrID.(type) {
	case uint:
		claims["user_id"] = v
	case *models.User:
		claims["user_id"] = v.ID
		claims["role"] = v.Role
	default:
		return "", fmt.Errorf("invalid argument type for generateToken")
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	secretKey := os.Getenv("JWT_SECRET")
	if secretKey == "" {
		secretKey = "your-secret-key-here" // Default value
	}

	return token.SignedString([]byte(secretKey))
}
