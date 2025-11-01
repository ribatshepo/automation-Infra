#!/bin/bash
set -e

echo "Generating basic project structure..."

# Create cmd/server/main.go
mkdir -p cmd/server
cat > cmd/server/main.go << 'EOF'
// Package main provides the entry point for the server application.
package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/your-org/project-name/internal/config"
	"github.com/your-org/project-name/internal/handlers"
	"github.com/your-org/project-name/internal/middleware"
)

var version = "dev"

func main() {
	// Load configuration
	cfg := config.Load()

	// Create router with middleware
	router := handlers.NewRouter()
	router.Use(middleware.Logger)
	router.Use(middleware.CORS)

	// Setup routes
	handlers.SetupRoutes(router)

	// Create server
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      router,
		ReadTimeout:  cfg.ReadTimeout,
		WriteTimeout: cfg.WriteTimeout,
		IdleTimeout:  cfg.IdleTimeout,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %d (version: %s)", cfg.Port, version)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Server shutting down...")

	// Create a deadline for shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Shutdown server
	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
EOF

# Create internal/config/config.go
mkdir -p internal/config
cat > internal/config/config.go << 'EOF'
// Package config provides application configuration.
package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds the application configuration.
type Config struct {
	Port         int
	Environment  string
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	IdleTimeout  time.Duration
}

// Load loads configuration from environment variables with defaults.
func Load() *Config {
	return &Config{
		Port:         getEnvInt("PORT", 8080),
		Environment:  getEnv("ENVIRONMENT", "development"),
		ReadTimeout:  getEnvDuration("READ_TIMEOUT", "15s"),
		WriteTimeout: getEnvDuration("WRITE_TIMEOUT", "15s"),
		IdleTimeout:  getEnvDuration("IDLE_TIMEOUT", "60s"),
	}
}

// getEnv gets an environment variable with a default value.
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvInt gets an integer environment variable with a default value.
func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

// getEnvDuration gets a duration environment variable with a default value.
func getEnvDuration(key, defaultValue string) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	if duration, err := time.ParseDuration(defaultValue); err == nil {
		return duration
	}
	return 30 * time.Second
}
EOF

# Create internal/handlers/handlers.go
mkdir -p internal/handlers
cat > internal/handlers/handlers.go << 'EOF'
// Package handlers provides HTTP request handlers.
package handlers

import (
	"encoding/json"
	"net/http"
	"runtime"
	"time"

	"github.com/gorilla/mux"
)

// Response represents a standard API response.
type Response struct {
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	Error     string      `json:"error,omitempty"`
	Timestamp time.Time   `json:"timestamp"`
}

// HealthResponse represents a health check response.
type HealthResponse struct {
	Status      string            `json:"status"`
	Version     string            `json:"version"`
	Environment string            `json:"environment"`
	Uptime      string            `json:"uptime"`
	System      map[string]string `json:"system"`
	Timestamp   time.Time         `json:"timestamp"`
}

var startTime = time.Now()

// NewRouter creates a new HTTP router.
func NewRouter() *mux.Router {
	return mux.NewRouter()
}

// SetupRoutes configures all application routes.
func SetupRoutes(router *mux.Router) {
	// Health endpoints
	router.HandleFunc("/health", HealthHandler).Methods("GET")
	router.HandleFunc("/ready", ReadyHandler).Methods("GET")

	// API routes
	api := router.PathPrefix("/api").Subrouter()
	api.HandleFunc("/", APIInfoHandler).Methods("GET")
	api.HandleFunc("/status", StatusHandler).Methods("GET")

	// Root endpoint
	router.HandleFunc("/", RootHandler).Methods("GET")
}

// RootHandler handles requests to the root endpoint.
func RootHandler(w http.ResponseWriter, r *http.Request) {
	response := Response{
		Message: "Welcome to Go API template",
		Data: map[string]interface{}{
			"version": "1.0.0",
			"endpoints": map[string]string{
				"health": "/health",
				"ready":  "/ready",
				"api":    "/api",
			},
		},
		Timestamp: time.Now(),
	}

	writeJSONResponse(w, http.StatusOK, response)
}

// HealthHandler handles health check requests.
func HealthHandler(w http.ResponseWriter, r *http.Request) {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	response := HealthResponse{
		Status:      "ok",
		Version:     "1.0.0",
		Environment: "development",
		Uptime:      time.Since(startTime).String(),
		System: map[string]string{
			"go_version":    runtime.Version(),
			"num_goroutine": string(rune(runtime.NumGoroutine())),
			"num_cpu":       string(rune(runtime.NumCPU())),
		},
		Timestamp: time.Now(),
	}

	writeJSONResponse(w, http.StatusOK, response)
}

// ReadyHandler handles readiness check requests.
func ReadyHandler(w http.ResponseWriter, r *http.Request) {
	response := Response{
		Message: "ready",
		Data: map[string]interface{}{
			"status": "ready",
		},
		Timestamp: time.Now(),
	}

	writeJSONResponse(w, http.StatusOK, response)
}

// APIInfoHandler handles API information requests.
func APIInfoHandler(w http.ResponseWriter, r *http.Request) {
	response := Response{
		Message: "API is running",
		Data: map[string]interface{}{
			"version": "1.0.0",
			"endpoints": []string{
				"GET /api/",
				"GET /api/status",
			},
		},
		Timestamp: time.Now(),
	}

	writeJSONResponse(w, http.StatusOK, response)
}

// StatusHandler handles status requests.
func StatusHandler(w http.ResponseWriter, r *http.Request) {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	response := Response{
		Message: "status",
		Data: map[string]interface{}{
			"status":       "active",
			"go_version":   runtime.Version(),
			"goroutines":   runtime.NumGoroutine(),
			"memory_alloc": memStats.Alloc,
			"memory_sys":   memStats.Sys,
			"uptime":       time.Since(startTime).String(),
		},
		Timestamp: time.Now(),
	}

	writeJSONResponse(w, http.StatusOK, response)
}

// writeJSONResponse writes a JSON response to the client.
func writeJSONResponse(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}
EOF

# Create internal/middleware/middleware.go
mkdir -p internal/middleware
cat > internal/middleware/middleware.go << 'EOF'
// Package middleware provides HTTP middleware functions.
package middleware

import (
	"log"
	"net/http"
	"time"

	"github.com/rs/cors"
)

// Logger is a middleware that logs HTTP requests.
func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Create a response writer wrapper to capture status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		// Call the next handler
		next.ServeHTTP(wrapped, r)

		// Log the request
		log.Printf(
			"%s %s %d %v %s",
			r.Method,
			r.RequestURI,
			wrapped.statusCode,
			time.Since(start),
			r.RemoteAddr,
		)
	})
}

// CORS returns a CORS middleware with default settings.
func CORS(next http.Handler) http.Handler {
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowedHeaders: []string{
			"Accept",
			"Authorization",
			"Content-Type",
			"X-CSRF-Token",
		},
		ExposedHeaders: []string{
			"Link",
		},
		AllowCredentials: false,
		MaxAge:           300,
	})

	return c.Handler(next)
}

// responseWriter wraps http.ResponseWriter to capture status code.
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

// WriteHeader captures the status code and calls the original WriteHeader.
func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}
EOF

# Create internal/services/services.go
mkdir -p internal/services
cat > internal/services/services.go << 'EOF'
// Package services provides business logic services.
package services

import (
	"errors"
	"strings"
	"time"
)

// ExampleService provides example business logic.
type ExampleService struct {
	// Add service dependencies here
}

// NewExampleService creates a new ExampleService.
func NewExampleService() *ExampleService {
	return &ExampleService{}
}

// GetData returns example data.
func (s *ExampleService) GetData() ([]map[string]interface{}, error) {
	// Simulate some processing time
	time.Sleep(10 * time.Millisecond)

	data := []map[string]interface{}{
		{
			"id":   1,
			"name": "Example 1",
			"type": "sample",
		},
		{
			"id":   2,
			"name": "Example 2",
			"type": "sample",
		},
	}

	return data, nil
}

// ProcessData processes input data and returns a result.
func (s *ExampleService) ProcessData(input string) (string, error) {
	if input == "" {
		return "", errors.New("input cannot be empty")
	}

	// Simulate processing
	time.Sleep(5 * time.Millisecond)

	processed := "processed: " + strings.ToUpper(input)
	return processed, nil
}

// ValidateInput validates input data.
func (s *ExampleService) ValidateInput(input map[string]interface{}) error {
	if input == nil {
		return errors.New("input cannot be nil")
	}

	requiredFields := []string{"name", "type"}
	for _, field := range requiredFields {
		if _, exists := input[field]; !exists {
			return errors.New("missing required field: " + field)
		}
	}

	return nil
}
EOF

# Create pkg/utils/utils.go
mkdir -p pkg/utils
cat > pkg/utils/utils.go << 'EOF'
// Package utils provides utility functions.
package utils

import (
	"crypto/rand"
	"encoding/hex"
	"regexp"
	"strings"
	"time"
)

// IsValidEmail validates email format.
func IsValidEmail(email string) bool {
	emailRegex := regexp.MustCompile(`^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$`)
	return emailRegex.MatchString(strings.ToLower(email))
}

// GenerateRandomString generates a random string of specified length.
func GenerateRandomString(length int) (string, error) {
	bytes := make([]byte, length/2)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes)[:length], nil
}

// StringInSlice checks if a string exists in a slice.
func StringInSlice(str string, slice []string) bool {
	for _, item := range slice {
		if item == str {
			return true
		}
	}
	return false
}

// FormatDuration formats a duration in a human-readable way.
func FormatDuration(d time.Duration) string {
	if d < time.Minute {
		return d.Round(time.Second).String()
	}
	if d < time.Hour {
		return d.Round(time.Minute).String()
	}
	return d.Round(time.Hour).String()
}

// TruncateString truncates a string to a maximum length.
func TruncateString(str string, maxLength int) string {
	if len(str) <= maxLength {
		return str
	}
	return str[:maxLength-3] + "..."
}

// SafeString removes potentially dangerous characters from a string.
func SafeString(input string) string {
	// Remove control characters and normalize whitespace
	reg := regexp.MustCompile(`[\x00-\x1f\x7f]`)
	cleaned := reg.ReplaceAllString(input, "")
	return strings.TrimSpace(cleaned)
}
EOF

echo "Basic project structure generated successfully!"