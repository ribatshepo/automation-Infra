#!/bin/bash

# .NET build script
set -e

echo "[INFO] Building .NET project..."

if ! command -v dotnet >/dev/null 2>&1; then
    echo "[ERROR] .NET SDK not installed"
    exit 1
fi

if dotnet build; then
    echo "[SUCCESS] Build completed"
else
    echo "[ERROR] Build failed"
    exit 1
fi