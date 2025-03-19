package config

import (
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

// setupServer configures and returns a Gin engine with optimized settings
func SetupServer() *gin.Engine {
	// Set Gin to release mode in production
	if os.Getenv("ENVIRONMENT") != "development" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create a new Gin engine with custom configuration
	r := gin.New()

	// Use custom recovery middleware
	r.Use(gin.Recovery())

	// Add custom logging middleware for production
	r.Use(func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		c.Next()

		if raw != "" {
			path = path + "?" + raw
		}

		latency := time.Since(start)
		if os.Getenv("ENVIRONMENT") == "production" {
			if c.Writer.Status() >= 400 {
				log.Printf("[ERROR] %s %s %d %s", c.Request.Method, path, c.Writer.Status(), latency)
			}
		} else {
			log.Printf("[INFO] %s %s %d %s", c.Request.Method, path, c.Writer.Status(), latency)
		}
	})

	return r
}
