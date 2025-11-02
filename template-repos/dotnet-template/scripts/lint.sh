#!/bin/bash

# .NET linting script
set -e

echo "[INFO] Running .NET code analysis..."

if ! command -v dotnet >/dev/null 2>&1; then
    echo "[ERROR] .NET SDK not installed"
    exit 1
fi

if dotnet format --verify-no-changes; then
    echo "[SUCCESS] Code formatting is correct"
else
    echo "[ERROR] Code formatting issues found"
    exit 1
fi