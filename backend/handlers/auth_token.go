package handlers

import (
	"fmt"
	"instagram-backend/models"
	"os"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v4"
)

func generateToken(userOrID interface{}) (string, error) {
	expiryDays, _ := strconv.Atoi(os.Getenv("JWT_EXPIRY_DAYS"))
	if expiryDays <= 0 {
		expiryDays = 7 // Default value
	}

	claims := jwt.MapClaims{
		"exp": time.Now().Add(time.Hour * 24 * time.Duration(expiryDays)).Unix(),
	}

	switch v := userOrID.(type) {
	case uint:
		claims["user_id"] = v
	case *models.User:
		claims["user_id"] = v.ID
		claims["role"] = v.Role
	default:
		return "", fmt.Errorf("invalid argument type for generateToken")
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	secretKey := os.Getenv("JWT_SECRET")
	if secretKey == "" {
		secretKey = "your-secret-key-here" // Default value
	}

	return token.SignedString([]byte(secretKey))
}