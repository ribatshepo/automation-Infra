#!/bin/bash

# .NET comprehensive check script
set -e

echo "[INFO] Running all .NET checks..."

# Build check
if ./scripts/build.sh; then
    echo "[SUCCESS] Build check passed"
else
    echo "[ERROR] Build check failed"
    exit 1
fi

# Test check
if ./scripts/test.sh; then
    echo "[SUCCESS] Test check passed"
else
    echo "[ERROR] Test check failed"
    exit 1
fi

# Lint check
if ./scripts/lint.sh; then
    echo "[SUCCESS] Lint check passed"
else
    echo "[ERROR] Lint check failed"
    exit 1
fi

# Security check
./scripts/security-check.sh

echo "[SUCCESS] All checks completed"