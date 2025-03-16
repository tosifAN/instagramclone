package models

// GormModel represents the common model fields used by gorm.Model
type GormModel struct {
	ID        uint   `json:"id" example:"1"`
	CreatedAt string `json:"created_at" example:"2024-03-15T10:00:00Z"`
	UpdatedAt string `json:"updated_at" example:"2024-03-15T10:00:00Z"`
	DeletedAt string `json:"deleted_at,omitempty" example:"2024-03-15T10:00:00Z"`
}

// SwaggerUser represents the User model for Swagger documentation
type SwaggerUser struct {
	GormModel
	Username     string           `json:"username" example:"john_doe"`
	Email        string           `json:"email" example:"john@example.com"`
	Name         string           `json:"name" example:"John Doe"`
	Bio          string           `json:"bio" example:"Software Developer"`
	ProfileImage string           `json:"profileImage" example:"https://example.com/profile.jpg"`
	Role         string           `json:"role" example:"seller"`
	Posts        []SwaggerPost    `json:"posts,omitempty"`
	Subscribers  []SwaggerUser    `json:"subscribers,omitempty"`
}

// SwaggerPost represents the Post model for Swagger documentation
type SwaggerPost struct {
	GormModel
	Caption         string                 `json:"caption" example:"Beautiful sunset"`
	PostImages      []SwaggerPostImage     `json:"postImages,omitempty"`
	VideoURL        string                 `json:"videoUrl,omitempty" example:"https://example.com/video.mp4"`
	LiveStreamURL   string                 `json:"liveStreamUrl,omitempty" example:"https://example.com/live"`
	UserID          uint                   `json:"userId" example:"1"`
	User            SwaggerUser            `json:"user"`
	ContentType     string                 `json:"contentType" example:"feed"`
	Likes           []SwaggerLike          `json:"likes,omitempty"`
	Comments        []SwaggerComment       `json:"comments,omitempty"`
	PurchaseOptions []SwaggerPurchaseOption `json:"purchaseOptions,omitempty"`
	Location        string                 `json:"location,omitempty" example:"New York"`
}

// SwaggerPostImage represents the PostImage model for Swagger documentation
type SwaggerPostImage struct {
	GormModel
	PostID   uint   `json:"postId" example:"1"`
	ImageURL string `json:"imageUrl" example:"https://example.com/image.jpg"`
}

// SwaggerComment represents the Comment model for Swagger documentation
type SwaggerComment struct {
	GormModel
	Content string      `json:"content" example:"Great post!"`
	PostID  uint        `json:"postId" example:"1"`
	UserID  uint        `json:"userId" example:"1"`
	User    SwaggerUser `json:"user"`
}

// SwaggerLike represents the Like model for Swagger documentation
type SwaggerLike struct {
	GormModel
	PostID uint        `json:"postId" example:"1"`
	UserID uint        `json:"userId" example:"1"`
	User   SwaggerUser `json:"user"`
}

// SwaggerPurchaseOption represents the PurchaseOption model for Swagger documentation
type SwaggerPurchaseOption struct {
	GormModel
	PostID   uint   `json:"postId" example:"1"`
	Platform string `json:"platform" example:"Amazon"`
	URL      string `json:"url" example:"https://amazon.com/product"`
}