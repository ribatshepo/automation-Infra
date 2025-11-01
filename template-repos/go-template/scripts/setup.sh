#!/bin/bash
set -e

echo "Setting up Go project..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Please install Go 1.21 or later."
    echo "Visit: https://golang.org/doc/install"
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | cut -d' ' -f3 | sed 's/go//')
REQUIRED_VERSION="1.21"

if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V -C; then
    echo "Go version $GO_VERSION is too old. Please upgrade to Go $REQUIRED_VERSION or later."
    exit 1
fi

# Initialize go module if not exists
if [ ! -f go.mod ]; then
    echo "Initializing Go module..."
    read -p "Enter module name (e.g., github.com/your-org/project-name): " MODULE_NAME
    go mod init "$MODULE_NAME"
fi

# Install development tools
echo "Installing development tools..."
make install-tools

# Download dependencies
echo "Downloading dependencies..."
make deps

# Create basic project structure if it doesn't exist
if [ ! -f cmd/server/main.go ]; then
    echo "Creating basic project structure..."
    ./scripts/generate-structure.sh
fi

# Initialize git if not already initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit from Go template"
fi

# Run initial checks
echo "Running initial checks..."
make lint || echo "Linting failed - please fix issues"
make test || echo "Tests failed - please add tests"

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update go.mod with your module name"
echo "2. Customize cmd/server/main.go for your application"
echo "3. Add your business logic to internal/ packages"
echo "4. Run tests with: make test"
echo "5. Build with: make build"
echo "6. Set up CI/CD with: ./scripts/setup-cicd.sh"