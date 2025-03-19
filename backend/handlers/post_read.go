package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"instagram-backend/cache"
	"instagram-backend/config"
	"instagram-backend/models"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// @Summary Get all posts
// @Description Get paginated list of posts with rate limiting and caching
// @Tags posts
// @Accept json
// @Produce json
// @Param page query int false "Page number"
// @Param pageSize query int false "Page size"
// @Success 200 {array} models.SwaggerPost
// @Header 200 {string} X-Cache "HIT when response is from cache, MISS otherwise"
// @Header 200 {string} Cache-Control "Caching directives"
// @Failure 429 {object} map[string]string "Rate limit exceeded"
// @Failure 500 {object} map[string]string
// @Security BearerAuth
// @Router /api/posts [get]
func (h *PostHandler) GetPosts(c *gin.Context) {
	// Apply rate limiting
	<-h.rateLimit.C

	// Add pagination
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	offset := (page - 1) * pageSize

	// Try to get posts from cache first
	cacheKey := fmt.Sprintf("posts:page:%d:size:%d", page, pageSize)
	redisClient := config.GetRedisClient()
	cachedData, err := redisClient.Get(context.Background(), cacheKey).Bytes()
	if err == nil {
		var response gin.H
		if err := json.Unmarshal(cachedData, &response); err == nil {
			c.Header("X-Cache", "HIT")
			c.Header("Cache-Control", "private, max-age=300")
			c.JSON(http.StatusOK, response)
			return
		}
	}

	// Use parallel processing for counting total posts
	totalChan := make(chan int64)
	postsChan := make(chan []models.Post)
	errorChan := make(chan error)

	// Count total posts in parallel
	go func() {
		var total int64
		if err := h.db.Model(&models.Post{}).Count(&total).Error; err != nil {
			errorChan <- err
			return
		}
		totalChan <- total
	}()

	// Fetch posts with pagination in parallel
	go func() {
		var posts []models.Post
		result := h.db.Preload("User").
			Preload("Likes").
			Preload("Comments").
			Preload("PostImages").
			Preload("PurchaseOptions").
			Order("created_at desc").
			Offset(offset).Limit(pageSize).
			Find(&posts)

		if result.Error != nil {
			errorChan <- result.Error
			return
		}
		postsChan <- posts
	}()

	// Wait for results
	select {
	case err := <-errorChan:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch posts: " + err.Error()})
		return
	case total := <-totalChan:
		posts := <-postsChan
		// Set cache headers
		c.Header("Cache-Control", "private, max-age=300")
		c.JSON(http.StatusOK, gin.H{
			"posts":      posts,
			"total":      total,
			"page":       page,
			"pageSize":   pageSize,
			"totalPages": (total + int64(pageSize) - 1) / int64(pageSize),
		})
	}
}

func (h *PostHandler) GetPost(c *gin.Context) {
	// Apply rate limiting
	<-h.rateLimit.C

	id := c.Param("id")
	postID, _ := strconv.ParseUint(id, 10, 32)

	// Try to get post from cache first
	cachedPost, err := cache.GetCachedPost(c.Request.Context(), uint(postID))
	if err == nil {
		c.Header("X-Cache", "HIT")
		c.Header("Cache-Control", "private, max-age=300")
		c.JSON(http.StatusOK, cachedPost)
		return
	}

	var post models.Post
	// Use parallel processing for fetching post and its associations
	postChan := make(chan *models.Post)
	errorChan := make(chan error)

	go func() {
		result := h.db.Preload("User").
			Preload("Likes").
			Preload("Comments.User").
			Preload("PostImages").
			Preload("PurchaseOptions").
			First(&post, id)

		if result.Error != nil {
			errorChan <- result.Error
			return
		}

		// Cache the post for future requests
		if err := cache.CachePost(c.Request.Context(), &post); err != nil {
			log.Printf("Failed to cache post: %v", err)
		}

		postChan <- &post
	}()

	// Wait for results
	select {
	case err := <-errorChan:
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch post: " + err.Error()})
		}
		return
	case post := <-postChan:
		// Set cache headers
		c.Header("Cache-Control", "private, max-age=300")
		c.JSON(http.StatusOK, post)
	}
}