package main

import (
	"context"
	"fmt"
	"instagram-backend/config"
	"instagram-backend/docs"
	"instagram-backend/handlers"
	"instagram-backend/middleware"
	"instagram-backend/models"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var db *gorm.DB

func init() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found")
	}
}

func setupDatabase() error {
	var err error
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "host=localhost user=postgres password=Tosif@123 dbname=instagram port=5432 sslmode=disable"
	}
	fmt.Println("DB Connection String:", dsn)

	// Configure connection pool and logging with optimized settings
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger:      logger.Default.LogMode(getLogLevel()),
		PrepareStmt: true, // Enable prepared statement cache
		NowFunc: func() time.Time { // Ensure consistent time handling
			return time.Now().UTC()
		},
		SkipDefaultTransaction: true, // Disable default transaction for better performance
		DisableAutomaticPing:   true, // Disable automatic ping
	})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	// Configure connection pool settings with optimized values
	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %v", err)
	}

	// Set optimized connection pool parameters
	sqlDB.SetMaxIdleConns(25)                  // Increased from 10
	sqlDB.SetMaxOpenConns(200)                 // Increased from 100
	sqlDB.SetConnMaxLifetime(30 * time.Minute) // Reduced from 1 hour for better resource management
	sqlDB.SetConnMaxIdleTime(10 * time.Minute) // Add idle timeout

	log.Println("Connected to database successfully")

	// Create channels for parallel migration processing
	errorChan := make(chan error)
	doneChan := make(chan bool)

	// Run migrations in a separate goroutine
	go func() {
		log.Println("Running database migrations...")
		err := db.AutoMigrate(
			&models.User{},
			&models.Post{},
			&models.Comment{},
			&models.Like{},
			&models.PostImage{},
			&models.PurchaseOption{},
			&models.Subscription{},
		)

		if err != nil {
			errorChan <- fmt.Errorf("failed to run migrations: %v", err)
			return
		}
		doneChan <- true
	}()

	// Wait for migration completion or timeout
	select {
	case err := <-errorChan:
		return err
	case <-doneChan:
		log.Println("Database migrations completed successfully")
	case <-time.After(2 * time.Minute): // Add timeout for migrations
		return fmt.Errorf("migration timeout after 2 minutes")
	}

	return nil
}

// getLogLevel returns the appropriate log level based on environment
func getLogLevel() logger.LogLevel {
	if os.Getenv("ENVIRONMENT") == "production" {
		return logger.Silent
	}
	return logger.Info
}

// setupServer configures and returns a Gin engine with optimized settings
func setupServer() *gin.Engine {
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

// @BasePath /api/v1
func setupRouter() *gin.Engine {
	r := setupServer()

	// Swagger documentation endpoint
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db)
	postHandler := handlers.NewPostHandler(db)

	// Public routes
	r.POST("/api/register", authHandler.Register)
	r.POST("/api/login", authHandler.Login)

	// Protected routes
	protected := r.Group("/api")
	protected.Use(middleware.AuthMiddleware())
	{
		// User routes
		protected.GET("/users/:id", authHandler.GetUser)
		protected.PUT("/users/:id", authHandler.UpdateUser)
		protected.GET("/users/:id/subscribers", authHandler.GetUserSubscribers)

		// Post routes
		protected.POST("/posts", postHandler.CreatePost)
		protected.GET("/posts", postHandler.GetPosts)
		protected.GET("/posts/:id", postHandler.GetPost)
		protected.PUT("/posts/:id", postHandler.UpdatePost)
		protected.DELETE("/posts/:id", postHandler.DeletePost)

		// Like routes
		protected.POST("/posts/:id/like", postHandler.LikePost)
		protected.DELETE("/posts/:id/like", postHandler.UnlikePost)

		// Comment routes
		protected.POST("/posts/:id/comments", postHandler.CreateComment)
		protected.GET("/posts/:id/comments", postHandler.GetComments)
		protected.DELETE("/posts/:id/comments/:commentId", postHandler.DeleteComment)
	}

	return r
}

func main() {
	// Initialize Swagger documentation
	docs.SwaggerInfo.Title = "Instagram Backend API"
	docs.SwaggerInfo.Description = "REST API for Instagram-like social media platform"
	docs.SwaggerInfo.Version = "1.0"
	docs.SwaggerInfo.BasePath = "/api/v1"

	// Setup database
	if err := setupDatabase(); err != nil {
		log.Fatalf("Failed to setup database: %v", err)
	}

	// Setup Redis
	if err := config.SetupRedis(); err != nil {
		log.Fatalf("Failed to setup Redis: %v", err)
	}
	defer config.CloseRedis()

	// Setup router
	router := setupRouter()

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
	if sqlDB, err := db.DB(); err == nil {
		sqlDB.Close()
	}
}
