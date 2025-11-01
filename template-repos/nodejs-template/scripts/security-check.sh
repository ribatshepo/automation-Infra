#!/bin/bash
set -e

echo "Running security checks..."

# Detect package manager
PACKAGE_MANAGER="npm"
if [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
fi

echo "Checking for known vulnerabilities..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn audit || echo "Vulnerabilities found - please review"
        ;;
    "pnpm")
        pnpm audit || echo "Vulnerabilities found - please review"
        ;;
    *)
        npm audit || echo "Vulnerabilities found - please review"
        ;;
esac

echo "Running security audit check..."
case $PACKAGE_MANAGER in
    "yarn")
        yarn security:check || echo "Security check failed - please review"
        ;;
    "pnpm")
        pnpm security:check || echo "Security check failed - please review"
        ;;
    *)
        npm run security:check || echo "Security check failed - please review"
        ;;
esac

echo "Security checks complete!"