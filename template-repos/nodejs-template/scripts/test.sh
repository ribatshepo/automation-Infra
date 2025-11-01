#!/bin/bash
set -e

echo "Running tests..."

# Detect package manager
PACKAGE_MANAGER="npm"
if [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
fi

# Run tests with coverage
case $PACKAGE_MANAGER in
    "yarn")
        yarn test:ci
        ;;
    "pnpm")
        pnpm test:ci
        ;;
    *)
        npm run test:ci
        ;;
esac

echo "Test coverage report generated in coverage/"