#!/bin/bash
set -e

echo "Running linting checks..."

# Run golangci-lint
if command -v golangci-lint &> /dev/null; then
    golangci-lint run
else
    echo "golangci-lint not found. Installing..."
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    golangci-lint run
fi

# Run go vet
echo "Running go vet..."
go vet ./...

# Check formatting
echo "Checking code formatting..."
if [ -n "$(gofmt -l .)" ]; then
    echo "Code is not formatted. Please run 'make format' or 'gofmt -w .'"
    gofmt -l .
    exit 1
fi

echo "All linting checks passed!"