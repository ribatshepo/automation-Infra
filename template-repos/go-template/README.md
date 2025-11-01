# Go Project Template

A minimal, extensible Go project template with modern tooling and CI/CD integration.

## Features

- **Module Management**: Go modules with proper versioning
- **Code Quality**: golangci-lint, gofmt, and go vet
- **Testing**: Testing with coverage reporting and benchmarks
- **Security**: Dependency scanning and vulnerability checks
- **Documentation**: Automated documentation generation
- **CI/CD Integration**: GitHub Actions workflows from cicd-templates
- **Performance**: Benchmarking and profiling tools
- **Extensible**: Easy to customize for web services, CLI tools, or libraries

## Quick Start

### 1. Use This Template
```bash
# Create new repository from template
gh repo create my-go-project --template automation-infra/go-template
cd my-go-project
```

### 2. Initialize Project
```bash
# Run setup script
./scripts/setup.sh

# Initialize Go module
go mod init github.com/your-org/project-name
```

### 3. Configure CI/CD
```bash
# Set up GitHub Actions (optional)
./scripts/setup-cicd.sh
```

## Project Structure

```
go-template/
├── README.md                    # This file
├── go.mod                      # Go module definition
├── go.sum                      # Go module checksums
├── .gitignore                  # Git ignore patterns
├── .golangci.yml               # golangci-lint configuration
├── Makefile                    # Build automation
├── .github/                    # GitHub workflows
│   └── workflows/
│       └── ci.yml              # Basic CI workflow
├── scripts/                    # Setup and utility scripts
│   ├── setup.sh               # Project initialization
│   ├── setup-cicd.sh          # CI/CD setup
│   ├── test.sh                # Run tests
│   ├── lint.sh                # Run linting
│   ├── format.sh              # Format code
│   ├── security-check.sh      # Security scanning
│   └── build.sh               # Build project
├── cmd/                        # Main applications
│   └── server/                 # Example server application
│       └── main.go
├── internal/                   # Private application code
│   ├── config/                 # Configuration
│   │   └── config.go
│   ├── handlers/               # HTTP handlers
│   │   └── handlers.go
│   ├── middleware/             # Middleware
│   │   └── middleware.go
│   └── services/               # Business logic
│       └── services.go
├── pkg/                        # Public library code
│   └── utils/                  # Utility functions
│       └── utils.go
├── api/                        # API definitions
│   └── openapi.yaml
├── tests/                      # Additional test files
│   ├── integration/            # Integration tests
│   │   └── main_test.go
│   └── benchmarks/             # Benchmark tests
│       └── benchmark_test.go
├── docs/                       # Documentation
│   ├── api.md
│   └── deployment.md
└── examples/                   # Usage examples
    └── client.go
```

## Configuration

### Go Module (go.mod)
```go
module github.com/your-org/project-name

go 1.21

require (
    // Add your dependencies here
)

require (
    // Indirect dependencies will be listed here
)
```

### Makefile
```makefile
# Build configuration
BINARY_NAME=project-name
BINARY_PATH=./bin/$(BINARY_NAME)
BUILD_FLAGS=-ldflags="-s -w"

# Go configuration
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod
GOFMT=gofmt
GOLINT=golangci-lint

.PHONY: all build test clean lint format deps security

# Default target
all: deps lint test build

# Build the application
build:
	$(GOBUILD) $(BUILD_FLAGS) -o $(BINARY_PATH) ./cmd/server

# Run tests
test:
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

# Run tests with coverage
test-coverage:
	$(GOTEST) -v -race -coverprofile=coverage.out ./...
	$(GOCMD) tool cover -html=coverage.out -o coverage.html

# Run benchmarks
benchmark:
	$(GOTEST) -bench=. -benchmem ./...

# Clean build artifacts
clean:
	$(GOCMD) clean
	rm -rf bin/
	rm -f coverage.out coverage.html

# Lint code
lint:
	$(GOLINT) run

# Format code
format:
	$(GOFMT) -s -w .
	$(GOCMD) mod tidy

# Download dependencies
deps:
	$(GOMOD) download
	$(GOMOD) tidy

# Security check
security:
	$(GOCMD) list -json -m all | nancy sleuth

# Install development tools
install-tools:
	$(GOCMD) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	$(GOCMD) install github.com/sonatypecommunity/nancy@latest

# Run all checks
check: deps lint test security

# Development server
dev:
	$(GOCMD) run ./cmd/server
```

### golangci-lint Configuration
```yaml
# .golangci.yml
run:
  timeout: 5m
  tests: true
  modules-download-mode: readonly

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - typecheck
    - unused
    - asasalint
    - asciicheck
    - bidichk
    - bodyclose
    - containedctx
    - contextcheck
    - cyclop
    - decorder
    - depguard
    - dogsled
    - dupl
    - dupword
    - durationcheck
    - errchkjson
    - errname
    - errorlint
    - execinquery
    - exhaustive
    - exportloopref
    - forbidigo
    - forcetypeassert
    - funlen
    - gci
    - ginkgolinter
    - gocheckcompilerdirectives
    - gochecknoinits
    - gocognit
    - goconst
    - gocritic
    - gocyclo
    - godot
    - godox
    - goerr113
    - gofmt
    - gofumpt
    - goheader
    - goimports
    - gomnd
    - gomoddirectives
    - gomodguard
    - goprintffuncname
    - gosec
    - grouper
    - importas
    - interfacebloat
    - ireturn
    - lll
    - loggercheck
    - maintidx
    - makezero
    - mirror
    - misspell
    - musttag
    - nakedret
    - nestif
    - nilerr
    - nilnil
    - nlreturn
    - noctx
    - nolintlint
    - nonamedreturns
    - nosprintfhostport
    - paralleltest
    - prealloc
    - predeclared
    - promlinter
    - reassign
    - revive
    - rowserrcheck
    - sqlclosecheck
    - stylecheck
    - tagliatelle
    - tenv
    - testableexamples
    - testpackage
    - thelper
    - tparallel
    - unconvert
    - unparam
    - usestdlibvars
    - varnamelen
    - wastedassign
    - whitespace
    - wrapcheck
    - wsl

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true
  
  govet:
    enable-all: true
    disable:
      - fieldalignment
  
  gocyclo:
    min-complexity: 15
  
  funlen:
    lines: 100
    statements: 50
  
  gocognit:
    min-complexity: 20

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - gosec
        - dupl
        - funlen
        - gocognit
    - path: cmd/
      linters:
        - gochecknoinits
```

## Development Workflow

### Setup Development Environment
```bash
# Install Go (1.21 or later)
# https://golang.org/doc/install

# Initialize project
./scripts/setup.sh

# Install development tools
make install-tools
```

### Daily Development
```bash
# Start development server
make dev

# Run tests
make test

# Run linting
make lint

# Format code
make format

# Build project
make build

# Run all checks
make check
```

### Dependency Management
```bash
# Add dependency
go get package-name

# Add specific version
go get package-name@version

# Update dependencies
go get -u ./...

# Tidy module
go mod tidy
```

## Testing

### Test Structure
```go
// internal/services/services_test.go
package services

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestExampleService(t *testing.T) {
    service := NewExampleService()
    
    t.Run("should return data", func(t *testing.T) {
        result, err := service.GetData()
        require.NoError(t, err)
        assert.NotEmpty(t, result)
    })
}

func TestExampleService_ProcessData(t *testing.T) {
    service := NewExampleService()
    
    tests := []struct {
        name     string
        input    string
        expected string
        wantErr  bool
    }{
        {
            name:     "valid input",
            input:    "test",
            expected: "processed: test",
            wantErr:  false,
        },
        {
            name:     "empty input",
            input:    "",
            expected: "",
            wantErr:  true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := service.ProcessData(tt.input)
            
            if tt.wantErr {
                assert.Error(t, err)
                return
            }
            
            require.NoError(t, err)
            assert.Equal(t, tt.expected, result)
        })
    }
}

func BenchmarkExampleService_ProcessData(b *testing.B) {
    service := NewExampleService()
    input := "benchmark test data"
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, _ = service.ProcessData(input)
    }
}
```

### Test Commands
```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with race detection
go test -race ./...

# Run specific test
go test -run TestExampleService ./internal/services

# Run benchmarks
go test -bench=. ./...

# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## CI/CD Integration

This template integrates with the automation-infra CI/CD templates:

### GitHub Actions Workflow
- Uses `cicd-templates/examples/main-go-deploy.yml`
- Automated testing and linting
- Security scanning
- Container building and deployment
- Performance benchmarking

### Workflow Configuration
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: automation-infra/cicd-templates/.github/workflows/main-go-deploy.yml@main
    with:
      go_version: "1.21"
      project_name: "my-go-project"
      run_tests: true
      run_benchmarks: true
      run_security_scan: true
      deploy_to_registry: false
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
```

## Customization

### Framework-Specific Extensions

#### Web Service with Gin
```bash
# Add Gin dependencies
go get github.com/gin-gonic/gin

# Update main.go for Gin
# Add middleware and routes
# Update tests for HTTP endpoints
```

#### CLI Application with Cobra
```bash
# Add Cobra dependencies
go get github.com/spf13/cobra

# Initialize CLI structure
cobra init --pkg-name github.com/your-org/project-name
```

#### gRPC Service
```bash
# Add gRPC dependencies
go get google.golang.org/grpc
go get google.golang.org/protobuf

# Add protocol buffer definitions
# Generate gRPC code
# Update CI/CD for gRPC deployment
```

### Database Integration
```bash
# Add database dependencies (example: PostgreSQL)
go get github.com/lib/pq
go get gorm.io/gorm
go get gorm.io/driver/postgres

# Add migration tools
go get -u github.com/golang-migrate/migrate/v4
```

## Security

### Dependency Scanning
- Automated vulnerability scanning with `nancy`
- License compliance checking
- Security advisories monitoring

### Code Security
- Static analysis with `gosec`
- Code review guidelines
- SAST integration in CI/CD

### Security Configuration
```bash
# Install security tools
go install github.com/securecodewarrior/nancy@latest
go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# Run security checks
gosec ./...
go list -json -m all | nancy sleuth
```

## Performance

### Benchmarking
```go
// Benchmark example
func BenchmarkProcessData(b *testing.B) {
    service := NewService()
    data := generateTestData()
    
    b.ResetTimer()
    b.ReportAllocs()
    
    for i := 0; i < b.N; i++ {
        result := service.ProcessData(data)
        _ = result // Prevent compiler optimization
    }
}

// Memory benchmark
func BenchmarkMemoryUsage(b *testing.B) {
    b.ReportAllocs()
    
    for i := 0; i < b.N; i++ {
        data := make([]byte, 1024)
        _ = data
    }
}
```

### Profiling
```bash
# CPU profiling
go test -cpuprofile=cpu.prof -bench=.

# Memory profiling
go test -memprofile=mem.prof -bench=.

# View profiles
go tool pprof cpu.prof
go tool pprof mem.prof
```

## Deployment Options

### Container Deployment
```dockerfile
# Multi-stage build for Go application
FROM golang:1.21-alpine AS builder

# Install dependencies
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server

# Production stage
FROM alpine:latest AS production

# Install ca-certificates for SSL/TLS
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

# Create non-root user
RUN adduser -D -s /bin/sh appuser
USER appuser

EXPOSE 8080

CMD ["./main"]
```

### Binary Distribution
- Cross-compilation for multiple platforms
- GitHub Releases automation
- Package managers (Homebrew, APT, etc.)

## Best Practices

### Code Organization
- Follow Go project layout standards
- Use internal/ for private code
- Keep main.go minimal
- Separate concerns properly

### Error Handling
- Use explicit error handling
- Wrap errors with context
- Implement proper logging
- Handle panics gracefully

### Performance
- Use context for cancellation
- Implement proper connection pooling
- Profile regularly
- Monitor memory usage

### Testing
- Write table-driven tests
- Use testify for assertions
- Implement benchmarks
- Test error conditions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run all checks: `make check`
5. Submit a pull request

## Support

- Documentation: [Project Docs](docs/)
- CI/CD Templates: [cicd-templates](../cicd-templates/)
- Issues: [GitHub Issues](https://github.com/your-org/project/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/project/discussions)