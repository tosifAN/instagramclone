package handlers

import (
	"os"
	"strconv"
	"time"

	"gorm.io/gorm"
)

type PostHandler struct {
	db        *gorm.DB
	rateLimit *time.Ticker
}

func NewPostHandler(db *gorm.DB) *PostHandler {
	requestsPerSecond, _ := strconv.Atoi(os.Getenv("RATE_LIMIT_REQUESTS_PER_SECOND"))
	if requestsPerSecond <= 0 {
		requestsPerSecond = 10 // Default value
	}
	return &PostHandler{
		db:        db,
		rateLimit: time.NewTicker(time.Second / time.Duration(requestsPerSecond)),
	}
}
