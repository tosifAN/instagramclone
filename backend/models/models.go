package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username     string `gorm:"uniqueIndex;not null" json:"username"`
	Email        string `gorm:"uniqueIndex;not null" json:"email"`
	Password     string `gorm:"not null" json:"-"`
	Name         string `json:"name"`
	Bio          string `json:"bio"`
	ProfileImage string `json:"profileImage"`
	Role         string `gorm:"not null" json:"role"` // "seller" or "buyer"
	Posts        []Post `gorm:"foreignKey:UserID" json:"posts,omitempty"`
	// For buyers: the sellers they subscribe to
	Subscriptions []Subscription `gorm:"foreignKey:SubscriberID" json:"subscriptions,omitempty"`
	// For sellers: the list of subscribers who follow them
	Subscribers []Subscription `gorm:"foreignKey:SellerID" json:"subscribers,omitempty"`
	CreatedAt   time.Time      `json:"createdAt"`
	UpdatedAt   time.Time      `json:"updatedAt"`
}

// username for sellers should be assigned as seller_work/sellername e.g., "clothers/tosif"

type Post struct {
	gorm.Model
	Caption string `json:"caption"`
	// For feed posts: multiple images can be attached via PostImages
	PostImages    []PostImage `gorm:"foreignKey:PostID" json:"postImages,omitempty"`
	VideoURL      string      `json:"videoUrl,omitempty"`      // used for reels
	LiveStreamURL string      `json:"liveStreamUrl,omitempty"` // used for live sessions
	UserID        uint        `json:"userId"`
	User          User        `json:"user"`
	ContentType   string      `json:"contentType"` // "feed", "reel", "live"
	Likes         []Like      `json:"likes,omitempty"`
	Comments      []Comment   `json:"comments,omitempty"`
	// PurchaseOptions contains a list of available purchase links (e.g., Amazon, Zomato)
	PurchaseOptions []PurchaseOption `gorm:"foreignKey:PostID" json:"purchaseOptions,omitempty"`
	Location        string           `json:"location,omitempty"`
	CreatedAt       time.Time        `json:"createdAt"`
	UpdatedAt       time.Time        `json:"updatedAt"`
}

// PostImage represents a single image associated with a feed post.
type PostImage struct {
	gorm.Model
	PostID   uint   `json:"postId"`
	ImageURL string `json:"imageUrl"`
}

// PurchaseOption represents a link where the product can be purchased.
type PurchaseOption struct {
	gorm.Model
	PostID   uint   `json:"postId"`
	Platform string `json:"platform"` // e.g., "Amazon", "Zomato"
	URL      string `json:"url"`
}

type Like struct {
	gorm.Model
	UserID    uint      `json:"userId"`
	User      User      `json:"user"`
	PostID    uint      `json:"postId"`
	Post      Post      `json:"-"`
	CreatedAt time.Time `json:"createdAt"`
}

type Comment struct {
	gorm.Model
	Content   string    `json:"content"`
	UserID    uint      `json:"userId"`
	User      User      `json:"user"`
	PostID    uint      `json:"postId"`
	Post      Post      `json:"-"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// Subscription replaces the generic follow model, representing a buyer subscribing to a seller.
type Subscription struct {
	gorm.Model
	SubscriberID uint      `json:"subscriberId"` // Buyer subscribing
	SellerID     uint      `json:"sellerId"`     // Seller being subscribed to
	Subscriber   User      `gorm:"foreignKey:SubscriberID" json:"subscriber"`
	Seller       User      `gorm:"foreignKey:SellerID" json:"seller"`
	CreatedAt    time.Time `json:"createdAt"`
}
