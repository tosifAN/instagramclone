package handlers

import (
	"instagram-backend/cache"
	"instagram-backend/models"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func (h *PostHandler) UpdatePost(c *gin.Context) {
	userID := c.GetUint("user_id")
	postID := c.Param("id")

	// Invalidate the post cache before updating
	id, _ := strconv.ParseUint(postID, 10, 32)
	if err := cache.InvalidatePostCache(c.Request.Context(), uint(id)); err != nil {
		log.Printf("Failed to invalidate post cache: %v", err)
	}

	// Find the post
	var post models.Post
	if err := h.db.First(&post, postID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	// Check if the user owns the post
	if post.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized to update this post"})
		return
	}

	// Bind the update data
	var updateData CreatePostRequest
	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update post fields
	post.Caption = updateData.Caption
	post.Location = updateData.Location

	// Update the post
	if err := h.db.Save(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update post"})
		return
	}

	c.JSON(http.StatusOK, post)
}