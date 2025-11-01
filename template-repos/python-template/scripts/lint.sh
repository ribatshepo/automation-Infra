#!/bin/bash
set -e

echo "Running linting checks..."

# Activate virtual environment if available
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

echo "Running flake8..."
uv run flake8 src/ tests/

echo "Running mypy..."
uv run mypy src/

echo "Running bandit security check..."
uv run bandit -r src/

echo "Checking import sorting..."
uv run isort --check-only --diff src/ tests/

echo "Checking code formatting..."
uv run black --check --diff src/ tests/

echo "All linting checks passed!"