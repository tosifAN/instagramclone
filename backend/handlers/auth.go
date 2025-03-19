package handlers

import (
	"os"
	"strconv"
	"time"

	"gorm.io/gorm"
)

type AuthHandler struct {
	db        *gorm.DB
	rateLimit *time.Ticker
}

func NewAuthHandler(db *gorm.DB) *AuthHandler {
	requestsPerSecond, _ := strconv.Atoi(os.Getenv("RATE_LIMIT_REQUESTS_PER_SECOND"))
	if requestsPerSecond <= 0 {
		requestsPerSecond = 10 // Default value
	}
	return &AuthHandler{
		db:        db,
		rateLimit: time.NewTicker(time.Second / time.Duration(requestsPerSecond)),
	}
}
