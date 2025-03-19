package handlers

import (
	"instagram-backend/models"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func (h *PostHandler) LikePost(c *gin.Context) {
	postID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	userID := c.GetUint("user_id")

	var existingLike models.Like
	result := h.db.Where("post_id = ? AND user_id = ?", postID, userID).First(&existingLike)
	if result.Error == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Post already liked"})
		return
	}

	like := models.Like{
		PostID: uint(postID),
		UserID: userID,
	}

	if result := h.db.Create(&like); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to like post"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Post liked successfully"})
}

func (h *PostHandler) UnlikePost(c *gin.Context) {
	postID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	userID := c.GetUint("user_id")

	result := h.db.Where("post_id = ? AND user_id = ?", postID, userID).Delete(&models.Like{})
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unlike post"})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Post not liked"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Post unliked successfully"})
}