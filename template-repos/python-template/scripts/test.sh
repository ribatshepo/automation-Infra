#!/bin/bash
set -e

echo "Running tests..."

# Activate virtual environment if available
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Run tests with coverage
uv run pytest \
    --cov=src \
    --cov-report=term-missing \
    --cov-report=html:htmlcov \
    --cov-report=xml \
    --junit-xml=test-results.xml \
    -v

echo "Test coverage report generated in htmlcov/"
echo "Test results saved to test-results.xml"