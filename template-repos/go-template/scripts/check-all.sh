#!/bin/bash
set -e

echo "Running all checks..."

# Format code first
echo "=== FORMATTING ==="
./scripts/format.sh

# Run linting
echo "=== LINTING ==="
./scripts/lint.sh

# Run security checks
echo "=== SECURITY ==="
./scripts/security-check.sh

# Run tests
echo "=== TESTING ==="
./scripts/test.sh

# Build project
echo "=== BUILDING ==="
./scripts/build.sh

echo "All checks completed successfully!"