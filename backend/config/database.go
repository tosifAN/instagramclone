package config

import (
	"fmt"
	"instagram-backend/models"
	"log"
	"os"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var Db *gorm.DB

func SetupDatabase() error {
	var err error
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "host=localhost user=postgres password=Tosif@123 dbname=instagram port=5432 sslmode=disable"
	}
	fmt.Println("DB Connection String:", dsn)

	// Configure connection pool and logging with optimized settings
	Db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
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
	sqlDB, err := Db.DB()
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
		err := Db.AutoMigrate(
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
