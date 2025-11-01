#!/bin/bash
set -e

echo "Formatting code..."

# Activate virtual environment if available
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

echo "Sorting imports with isort..."
uv run isort src/ tests/

echo "Formatting code with black..."
uv run black src/ tests/

echo "Code formatting complete!"