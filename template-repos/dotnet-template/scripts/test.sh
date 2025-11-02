#!/bin/bash

# .NET testing script
set -e

echo "[INFO] Running .NET tests..."

if ! command -v dotnet >/dev/null 2>&1; then
    echo "[ERROR] .NET SDK not installed"
    exit 1
fi

if dotnet test; then
    echo "[SUCCESS] All tests passed"
else
    echo "[ERROR] Tests failed"
    exit 1
fi