#!/bin/bash
set -e

echo "Formatting code..."

# Detect package manager
PACKAGE_MANAGER="npm"
if [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
fi

echo "Fixing linting issues..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn lint:fix
        ;;
    "pnpm")
        pnpm lint:fix
        ;;
    *)
        npm run lint:fix
        ;;
esac

echo "Formatting with Prettier..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn format
        ;;
    "pnpm")
        pnpm format
        ;;
    *)
        npm run format
        ;;
esac

echo "Code formatting complete!"