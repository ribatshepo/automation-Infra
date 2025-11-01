#!/bin/bash
set -e

echo "Formatting code..."

# Format Go code
echo "Running gofmt..."
gofmt -s -w .

# Tidy go.mod
echo "Tidying go.mod..."
go mod tidy

# Run goimports if available
if command -v goimports &> /dev/null; then
    echo "Running goimports..."
    goimports -w .
else
    echo "goimports not found. Installing..."
    go install golang.org/x/tools/cmd/goimports@latest
    goimports -w .
fi

echo "Code formatting complete!"