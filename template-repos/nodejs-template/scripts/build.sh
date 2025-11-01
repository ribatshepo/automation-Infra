#!/bin/bash
set -e

echo "Building project..."

# Detect package manager
PACKAGE_MANAGER="npm"
if [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
fi

echo "Cleaning previous build..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn clean
        ;;
    "pnpm")
        pnpm clean
        ;;
    *)
        npm run clean
        ;;
esac

echo "Building TypeScript..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn build
        ;;
    "pnpm")
        pnpm build
        ;;
    *)
        npm run build
        ;;
esac

echo "Build complete! Output in dist/"