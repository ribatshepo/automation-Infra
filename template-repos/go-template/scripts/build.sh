#!/bin/bash
set -euo pipefail

echo "Building project..."

# Clean previous builds
echo "Cleaning previous builds..."
make clean

# Build the application
echo "Building application..."
make build

# Build for multiple platforms if requested
if [[ "$1" == "--all" ]]; then
    echo "Building for multiple platforms..."
    make build-all
fi

echo "Build complete!"
echo "Binary location: ./bin/"
ls -la ./bin/