package config

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	RedisClient *redis.Client
	ctx         = context.Background()
)

// SetupRedis initializes the Redis client with optimized connection pooling
func SetupRedis() error {
	// Default to localhost if REDIS_URL is not set
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "localhost:6379"
	}

	// Configure Redis client with optimized settings
	RedisClient = redis.NewClient(&redis.Options{
		Addr:         redisURL,
		Password:     "", // no password by default
		DB:           0,  // use default DB
		PoolSize:     100,
		MinIdleConns: 10,
		MaxRetries:   3,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolTimeout:  4 * time.Second,
	})

	// Test the connection
	pong, err := RedisClient.Ping(ctx).Result()
	if err != nil {
		return err
	}

	log.Printf("Connected to Redis: %s", pong)
	return nil
}

// GetRedisClient returns the Redis client instance
func GetRedisClient() *redis.Client {
	return RedisClient
}

// CloseRedis closes the Redis client connection
func CloseRedis() error {
	if RedisClient != nil {
		return RedisClient.Close()
	}
	return nil
}
