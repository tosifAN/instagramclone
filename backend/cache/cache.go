package cache

import (
	"context"
	"encoding/json"
	"instagram-backend/config"
	"instagram-backend/models"
	"time"
)

const (
	PostCachePrefix    = "post:"
	UserCachePrefix    = "user:"
	DefaultExpiration = 30 * time.Minute
)

// CachePost caches a post with its associations
func CachePost(ctx context.Context, post *models.Post) error {
	redis := config.GetRedisClient()
	data, err := json.Marshal(post)
	if err != nil {
		return err
	}

	return redis.Set(ctx, PostCachePrefix+string(post.ID), data, DefaultExpiration).Err()
}

// GetCachedPost retrieves a cached post
func GetCachedPost(ctx context.Context, postID uint) (*models.Post, error) {
	redis := config.GetRedisClient()
	data, err := redis.Get(ctx, PostCachePrefix+string(postID)).Bytes()
	if err != nil {
		return nil, err
	}

	var post models.Post
	if err := json.Unmarshal(data, &post); err != nil {
		return nil, err
	}

	return &post, nil
}

// CacheUser caches a user profile
func CacheUser(ctx context.Context, user *models.User) error {
	redis := config.GetRedisClient()
	data, err := json.Marshal(user)
	if err != nil {
		return err
	}

	return redis.Set(ctx, UserCachePrefix+string(user.ID), data, DefaultExpiration).Err()
}

// GetCachedUser retrieves a cached user profile
func GetCachedUser(ctx context.Context, userID uint) (*models.User, error) {
	redis := config.GetRedisClient()
	data, err := redis.Get(ctx, UserCachePrefix+string(userID)).Bytes()
	if err != nil {
		return nil, err
	}

	var user models.User
	if err := json.Unmarshal(data, &user); err != nil {
		return nil, err
	}

	return &user, nil
}

// InvalidatePostCache removes a post from cache
func InvalidatePostCache(ctx context.Context, postID uint) error {
	return config.GetRedisClient().Del(ctx, PostCachePrefix+string(postID)).Err()
}

// InvalidateUserCache removes a user from cache
func InvalidateUserCache(ctx context.Context, userID uint) error {
	return config.GetRedisClient().Del(ctx, UserCachePrefix+string(userID)).Err()
}