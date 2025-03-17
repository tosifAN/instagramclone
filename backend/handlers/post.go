package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"instagram-backend/cache"
	"instagram-backend/config"
	"instagram-backend/models"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type PostHandler struct {
	db        *gorm.DB
	rateLimit *time.Ticker
}

func NewPostHandler(db *gorm.DB) *PostHandler {
	return &PostHandler{
		db:        db,
		rateLimit: time.NewTicker(time.Second / 10), // Limit to 10 requests per second
	}
}

type PurchaseOptionRequest struct {
	Platform string `json:"platform" binding:"required"`
	URL      string `json:"url" binding:"required"`
}

type CreatePostRequest struct {
	Caption         string                  `json:"caption"`
	ContentType     string                  `json:"contentType" binding:"required"` // "feed", "reel", or "live"
	ImageURLs       []string                `json:"imageUrls,omitempty"`            // for feed posts
	VideoURL        string                  `json:"videoUrl,omitempty"`             // for reel posts
	LiveStreamURL   string                  `json:"liveStreamUrl,omitempty"`        // for live posts
	Location        string                  `json:"location,omitempty"`
	PurchaseOptions []PurchaseOptionRequest `json:"purchaseOptions,omitempty"`
}

// @Summary Create a new post
// @Description Create a new post with images, video, or live stream
// @Tags posts
// @Accept json
// @Produce json
// @Param post body CreatePostRequest true "Post creation information"
// @Success 201 {object} models.SwaggerPost
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Security BearerAuth
// @Router /api/posts [post]
func (h *PostHandler) CreatePost(c *gin.Context) {
	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetUint("user_id")

	// Create the post object with common fields.
	post := models.Post{
		Caption:     req.Caption,
		UserID:      userID,
		Location:    req.Location,
		ContentType: req.ContentType,
	}

	// Depending on the content type, assign the relevant field.
	switch req.ContentType {
	case "feed":
		// For feed posts, images will be attached after post creation.
	case "reel":
		post.VideoURL = req.VideoURL
	case "live":
		post.LiveStreamURL = req.LiveStreamURL
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid content type"})
		return
	}

	// Create the post record.
	if result := h.db.Create(&post); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
		return
	}

	// For feed posts, create PostImage records.
	if req.ContentType == "feed" && len(req.ImageURLs) > 0 {
		for _, url := range req.ImageURLs {
			postImage := models.PostImage{
				PostID:   post.ID,
				ImageURL: url,
			}
			h.db.Create(&postImage)
		}
	}

	// Create purchase options if provided.
	if len(req.PurchaseOptions) > 0 {
		for _, po := range req.PurchaseOptions {
			purchaseOption := models.PurchaseOption{
				PostID:   post.ID,
				Platform: po.Platform,
				URL:      po.URL,
			}
			h.db.Create(&purchaseOption)
		}
	}

	// Load the post with associations for the response.
	h.db.Preload("User").
		Preload("PostImages").
		Preload("PurchaseOptions").
		First(&post, post.ID)

	c.JSON(http.StatusCreated, post)
}

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
		// Temporarily remove cache implementation until package is ready

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

func (h *PostHandler) DeletePost(c *gin.Context) {
	id := c.Param("id")
	userID := c.GetUint("user_id")

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

func (h *PostHandler) CreateComment(c *gin.Context) {
	postID, _ := strconv.ParseUint(c.Param("id"), 10, 32)
	userID := c.GetUint("user_id")

	var req struct {
		Content string `json:"content" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	comment := models.Comment{
		Content: req.Content,
		PostID:  uint(postID),
		UserID:  userID,
	}

	if result := h.db.Create(&comment); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create comment"})
		return
	}

	// Load the user data for the response.
	h.db.Preload("User").First(&comment, comment.ID)

	c.JSON(http.StatusCreated, comment)
}

func (h *PostHandler) UpdatePost(c *gin.Context) {
	userID := c.GetUint("user_id")
	postID := c.Param("id")

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

func (h *PostHandler) GetComments(c *gin.Context) {
	postID := c.Param("id")

	// Get comments with user information
	var comments []models.Comment
	if err := h.db.Preload("User").Where("post_id = ?", postID).Find(&comments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch comments"})
		return
	}

	c.JSON(http.StatusOK, comments)
}

func (h *PostHandler) DeleteComment(c *gin.Context) {
	userID := c.GetUint("user_id")
	commentID := c.Param("commentId")

	// Find the comment
	var comment models.Comment
	if err := h.db.First(&comment, commentID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Comment not found"})
		return
	}

	// Check if the user owns the comment
	if comment.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized to delete this comment"})
		return
	}

	// Delete the comment
	if err := h.db.Delete(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete comment"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Comment deleted successfully"})
}

func (h *PostHandler) GetPostComments(c *gin.Context) {
	postID := c.Param("id")
	var comments []models.Comment
	result := h.db.Preload("User").
		Where("post_id = ?", postID).
		Order("created_at desc").
		Find(&comments)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch comments"})
		return
	}

	c.JSON(http.StatusOK, comments)
}
