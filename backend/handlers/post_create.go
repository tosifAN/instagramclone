package handlers

import (
	"net/http"
	"instagram-backend/models"

	"github.com/gin-gonic/gin"
)

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