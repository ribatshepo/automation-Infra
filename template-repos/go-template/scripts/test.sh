#!/bin/bash
set -euo pipefail

echo "Running tests..."

# Run tests with coverage
go test -v -race -coverprofile=coverage.out ./...

# Generate coverage report
go tool cover -html=coverage.out -o coverage.html

echo "Tests completed!"
echo "Coverage report generated: coverage.html"
echo ""
echo "Coverage summary:"
go tool cover -func=coverage.out | tail -1