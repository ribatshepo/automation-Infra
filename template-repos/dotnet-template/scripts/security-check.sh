#!/bin/bash

# .NET security check script
set -e

echo "[INFO] Running .NET security checks..."

if ! command -v dotnet >/dev/null 2>&1; then
    echo "[ERROR] .NET SDK not installed"
    exit 1
fi

if dotnet list package --vulnerable; then
    echo "[SUCCESS] No security vulnerabilities found"
else
    echo "[WARNING] Security vulnerabilities detected"
fi