#!/bin/bash
set -e

echo "Running all checks..."

# Run build first
echo "=== BUILDING ==="
./scripts/build.sh

# Run formatting
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

echo "All checks completed successfully!"