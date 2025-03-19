package main

import (
	"context"
	"instagram-backend/config"
	"instagram-backend/router"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/joho/godotenv"
)

func init() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found")
	}
}

func main() {

	// Setup database
	if err := config.SetupDatabase(); err != nil {
		log.Fatalf("Failed to setup database: %v", err)
	}

	// Setup Redis
	if err := config.SetupRedis(); err != nil {
		log.Fatalf("Failed to setup Redis: %v", err)
	}
	defer config.CloseRedis()

	// Setup router
	router := router.SetupRouter()

	// Configure port
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	readTimeout, _ := time.ParseDuration(os.Getenv("READ_TIMEOUT"))
	writeTimeout, _ := time.ParseDuration(os.Getenv("WRITE_TIMEOUT"))
	idleTimeout, _ := time.ParseDuration(os.Getenv("IDLE_TIMEOUT"))

	// Create server with timeouts
	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      router,
		ReadTimeout:  readTimeout,
		WriteTimeout: writeTimeout,
		IdleTimeout:  idleTimeout,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on http://localhost:%s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)
	<-quit

	// Graceful shutdown
	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exiting")

	// Close database connection
	if sqlDB, err := config.Db.DB(); err == nil {
		sqlDB.Close()
	}
}
