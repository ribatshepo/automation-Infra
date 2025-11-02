#!/bin/bash

# .NET formatting script
set -e

echo "[INFO] Formatting .NET code..."

if ! command -v dotnet >/dev/null 2>&1; then
    echo "[ERROR] .NET SDK not installed"
    exit 1
fi

if dotnet format; then
    echo "[SUCCESS] Code formatted"
else
    echo "[ERROR] Code formatting failed"
    exit 1
fi