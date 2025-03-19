package handlers

import (
	"instagram-backend/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Name     string `json:"name" binding:"required"`
	Role     string `json:"role" binding:"required,oneof=buyer seller"` // "buyer" or "seller"
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
