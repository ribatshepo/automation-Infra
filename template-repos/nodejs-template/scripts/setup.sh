#!/bin/bash
set -e

echo "Setting up Node.js project..."

# Check Node.js version
if [ -f .nvmrc ]; then
    if command -v nvm &> /dev/null; then
        echo "Using Node.js version from .nvmrc"
        nvm use
    else
        REQUIRED_VERSION=$(cat .nvmrc)
        CURRENT_VERSION=$(node --version | sed 's/v//')
        echo "Required Node.js version: $REQUIRED_VERSION"
        echo "Current Node.js version: $CURRENT_VERSION"
    fi
fi

# Detect package manager preference
PACKAGE_MANAGER="npm"
if [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
fi

echo "Using package manager: $PACKAGE_MANAGER"

# Install dependencies
echo "Installing dependencies..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn install
        ;;
    "pnpm")
        pnpm install
        ;;
    *)
        npm install
        ;;
esac

# Setup Husky for git hooks
echo "Setting up git hooks..."
if [ -d .git ]; then
    case $PACKAGE_MANAGER in
        "yarn")
            yarn husky install
            ;;
        "pnpm")
            pnpm husky install
            ;;
        *)
            npm run prepare
            ;;
    esac
else
    echo "Git repository not found. Initialize git first."
fi

# Initialize git if not already initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit from Node.js template"
    
    # Setup Husky after git init
    case $PACKAGE_MANAGER in
        "yarn")
            yarn husky install
            ;;
        "pnpm")
            pnpm husky install
            ;;
        *)
            npm run prepare
            ;;
    esac
fi

# Create necessary directories
mkdir -p src/{routes,middleware,services,utils}
mkdir -p tests/{unit,integration}
mkdir -p docs

# Generate basic files if they don't exist
if [ ! -f src/index.ts ]; then
    echo "Creating basic project structure..."
    ./scripts/generate-structure.sh
fi

# Build the project
echo "Building project..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn build
        ;;
    "pnpm")
        pnpm build
        ;;
    *)
        npm run build
        ;;
esac

# Run initial checks
echo "Running initial checks..."
./scripts/lint.sh || echo "Linting failed - please fix issues"
./scripts/test.sh || echo "Tests failed - please add tests"

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update package.json with your project details"
echo "2. Start development server: $PACKAGE_MANAGER run dev"
echo "3. Start coding in src/"
echo "4. Run tests with: $PACKAGE_MANAGER test"
echo "5. Set up CI/CD with: ./scripts/setup-cicd.sh"