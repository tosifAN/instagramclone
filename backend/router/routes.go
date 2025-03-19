package router

import (
	"instagram-backend/config"
	"instagram-backend/handlers"
	"instagram-backend/middleware"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// @BasePath /api/v1
func SetupRouter() *gin.Engine {
	r := config.SetupServer()

	// Swagger documentation endpoint
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(config.Db)
	postHandler := handlers.NewPostHandler(config.Db)

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		// Public routes
		v1.POST("/register", authHandler.Register)
		v1.POST("/login", authHandler.Login)

		// Protected routes
		protected := v1.Group("/")
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
	}
	return r
}
