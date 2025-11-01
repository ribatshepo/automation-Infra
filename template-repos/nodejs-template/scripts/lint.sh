#!/bin/bash
set -e

echo "Running linting checks..."

# Detect package manager
PACKAGE_MANAGER="npm"
if [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
fi

echo "Type checking..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn type-check
        ;;
    "pnpm")
        pnpm type-check
        ;;
    *)
        npm run type-check
        ;;
esac

echo "Linting..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn lint
        ;;
    "pnpm")
        pnpm lint
        ;;
    *)
        npm run lint
        ;;
esac

echo "Checking code formatting..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn format:check
        ;;
    "pnpm")
        pnpm format:check
        ;;
    *)
        npm run format:check
        ;;
esac

echo "All linting checks passed!"