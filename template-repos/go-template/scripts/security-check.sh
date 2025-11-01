#!/bin/bash
set -e

echo "Running security checks..."

# Check for vulnerabilities using govulncheck
if command -v govulncheck &> /dev/null; then
    echo "Running govulncheck..."
    govulncheck ./...
else
    echo "govulncheck not found. Installing..."
    go install golang.org/x/vuln/cmd/govulncheck@latest
    govulncheck ./...
fi

# Check dependencies with nancy
if command -v nancy &> /dev/null; then
    echo "Running nancy security scan..."
    go list -json -m all | nancy sleuth
else
    echo "nancy not found. Installing..."
    go install github.com/sonatypecommunity/nancy@latest
    go list -json -m all | nancy sleuth
fi

# Run gosec if available
if command -v gosec &> /dev/null; then
    echo "Running gosec..."
    gosec ./...
else
    echo "gosec not found. Installing..."
    go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
    gosec ./...
fi

echo "Security checks complete!"