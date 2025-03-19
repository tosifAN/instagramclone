package handlers

import (
	"instagram-backend/cache"
	"instagram-backend/models"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

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