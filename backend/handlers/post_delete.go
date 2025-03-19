package handlers

import (
	"instagram-backend/cache"
	"instagram-backend/models"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func (h *PostHandler) DeletePost(c *gin.Context) {
	id := c.Param("id")
	userID := c.GetUint("user_id")

	// Invalidate the post cache before deletion
	postID, _ := strconv.ParseUint(id, 10, 32)
	if err := cache.InvalidatePostCache(c.Request.Context(), uint(postID)); err != nil {
		log.Printf("Failed to invalidate post cache: %v", err)
	}

	var post models.Post
	if result := h.db.First(&post, id); result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	if post.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized to delete this post"})
		return
	}

	if result := h.db.Delete(&post); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete post"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Post deleted successfully"})
}