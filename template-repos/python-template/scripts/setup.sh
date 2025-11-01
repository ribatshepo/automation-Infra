#!/bin/bash
set -e

echo "Setting up Python project..."

# Check if UV is installed
if ! command -v uv &> /dev/null; then
    echo "Installing UV..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Create virtual environment and install dependencies
echo "Creating virtual environment..."
uv venv

echo "Installing dependencies..."
uv sync --dev

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
uv run pre-commit install

# Initialize git if not already initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit from Python template"
fi

# Create necessary directories
mkdir -p src/project_name/core
mkdir -p tests
mkdir -p docs
mkdir -p examples
mkdir -p .github/workflows

# Generate basic files if they don't exist
if [ ! -f src/project_name/__init__.py ]; then
    echo "Creating basic project structure..."
    ./scripts/generate-structure.sh
fi

# Run initial checks
echo "Running initial checks..."
./scripts/lint.sh || echo "Linting failed - please fix issues"
./scripts/test.sh || echo "Tests failed - please add tests"

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Activate virtual environment: source .venv/bin/activate"
echo "2. Update pyproject.toml with your project details"
echo "3. Start coding in src/project_name/"
echo "4. Run tests with: ./scripts/test.sh"
echo "5. Set up CI/CD with: ./scripts/setup-cicd.sh"