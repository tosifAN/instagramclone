package config

import (
	"context"
	"log"
	"os"
	"strconv"
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

	// Get Redis configuration from environment variables
	poolSize, _ := strconv.Atoi(os.Getenv("REDIS_POOL_SIZE"))
	minIdleConns, _ := strconv.Atoi(os.Getenv("REDIS_MIN_IDLE_CONNS"))
	maxRetries, _ := strconv.Atoi(os.Getenv("REDIS_MAX_RETRIES"))
	dialTimeout, _ := strconv.Atoi(os.Getenv("REDIS_DIAL_TIMEOUT"))
	readTimeout, _ := strconv.Atoi(os.Getenv("REDIS_READ_TIMEOUT"))
	writeTimeout, _ := strconv.Atoi(os.Getenv("REDIS_WRITE_TIMEOUT"))
	poolTimeout, _ := strconv.Atoi(os.Getenv("REDIS_POOL_TIMEOUT"))

	// Configure Redis client with settings from environment variables
	RedisClient = redis.NewClient(&redis.Options{
		Addr:         redisURL,
		Password:     "", // no password by default
		DB:           0,  // use default DB
		PoolSize:     poolSize,
		MinIdleConns: minIdleConns,
		MaxRetries:   maxRetries,
		DialTimeout:  time.Duration(dialTimeout) * time.Second,
		ReadTimeout:  time.Duration(readTimeout) * time.Second,
		WriteTimeout: time.Duration(writeTimeout) * time.Second,
		PoolTimeout:  time.Duration(poolTimeout) * time.Second,
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
