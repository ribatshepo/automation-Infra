# Build configuration
BINARY_NAME=project-name
BINARY_PATH=./bin/$(BINARY_NAME)
BUILD_FLAGS=-ldflags="-s -w -X main.version=$(shell git describe --tags --always --dirty)"

# Go configuration
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod
GOFMT=gofmt
GOLINT=golangci-lint

# Directories
SRC_DIR=./cmd/server
COVERAGE_DIR=./coverage

.PHONY: all build test clean lint format deps security benchmark install-tools help

# Default target
all: deps lint test build

# Build the application
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p bin
	$(GOBUILD) $(BUILD_FLAGS) -o $(BINARY_PATH) $(SRC_DIR)

# Build for multiple platforms
build-all:
	@echo "Building for multiple platforms..."
	@mkdir -p bin
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) -o $(BINARY_PATH)-linux-amd64 $(SRC_DIR)
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) -o $(BINARY_PATH)-darwin-amd64 $(SRC_DIR)
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) -o $(BINARY_PATH)-windows-amd64.exe $(SRC_DIR)

# Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	@mkdir -p $(COVERAGE_DIR)
	$(GOTEST) -v -race -coverprofile=$(COVERAGE_DIR)/coverage.out ./...
	$(GOCMD) tool cover -html=$(COVERAGE_DIR)/coverage.out -o $(COVERAGE_DIR)/coverage.html
	@echo "Coverage report generated: $(COVERAGE_DIR)/coverage.html"

# Run benchmarks
benchmark:
	@echo "Running benchmarks..."
	$(GOTEST) -bench=. -benchmem -run=^$$ ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCMD) clean
	rm -rf bin/
	rm -rf $(COVERAGE_DIR)/
	rm -f coverage.out

# Lint code
lint:
	@echo "Running linters..."
	$(GOLINT) run

# Format code
format:
	@echo "Formatting code..."
	$(GOFMT) -s -w .
	$(GOCMD) mod tidy

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy

# Security check
security:
	@echo "Running security checks..."
	$(GOCMD) list -json -m all | nancy sleuth

# Vulnerability check
vulncheck:
	@echo "Running vulnerability check..."
	govulncheck ./...

# Install development tools
install-tools:
	@echo "Installing development tools..."
	$(GOCMD) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	$(GOCMD) install github.com/sonatypecommunity/nancy@latest
	$(GOCMD) install golang.org/x/vuln/cmd/govulncheck@latest

# Run all checks
check: deps lint test security

# Development server with hot reload
dev:
	@echo "Starting development server..."
	$(GOCMD) run $(SRC_DIR)/main.go

# Run with race detection
dev-race:
	@echo "Starting development server with race detection..."
	$(GOCMD) run -race $(SRC_DIR)/main.go

# Install the application
install: build
	@echo "Installing $(BINARY_NAME)..."
	cp $(BINARY_PATH) $(GOPATH)/bin/

# Generate documentation
docs:
	@echo "Generating documentation..."
	godoc -http=:6060

# Run static analysis
analyze:
	@echo "Running static analysis..."
	$(GOCMD) vet ./...
	staticcheck ./...

# Help target
help:
	@echo "Available targets:"
	@echo "  all          - Run deps, lint, test, and build"
	@echo "  build        - Build the application"
	@echo "  build-all    - Build for multiple platforms"
	@echo "  test         - Run tests"
	@echo "  test-coverage- Run tests with coverage report"
	@echo "  benchmark    - Run benchmarks"
	@echo "  clean        - Clean build artifacts"
	@echo "  lint         - Run linters"
	@echo "  format       - Format code"
	@echo "  deps         - Download dependencies"
	@echo "  security     - Run security checks"
	@echo "  vulncheck    - Run vulnerability check"
	@echo "  install-tools- Install development tools"
	@echo "  check        - Run all checks"
	@echo "  dev          - Start development server"
	@echo "  dev-race     - Start development server with race detection"
	@echo "  install      - Install the application"
	@echo "  docs         - Generate documentation"
	@echo "  analyze      - Run static analysis"
	@echo "  help         - Show this help"