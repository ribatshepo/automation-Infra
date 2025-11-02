#!/bin/bash

# Docker Build Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
IMAGE_NAME=${1:-$(basename "$(pwd)")}
IMAGE_TAG=${2:-"latest"}
DOCKERFILE=${3:-"Dockerfile"}
BUILD_CONTEXT=${4:-"."}
HARBOR_URL=${HARBOR_URL:-"harbor.local"}
HARBOR_PROJECT=${HARBOR_PROJECT:-"library"}

print_status "Building Docker image..."
print_status "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
print_status "Dockerfile: ${DOCKERFILE}"
print_status "Context: ${BUILD_CONTEXT}"

# Check if Dockerfile exists
if [[ ! -f "${DOCKERFILE}" ]]; then
    print_error "Dockerfile not found: ${DOCKERFILE}"
    exit 1
fi

# Build the image
print_status "Starting Docker build..."
if docker build \
    --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
    --tag "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}" \
    --tag "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest" \
    --file "${DOCKERFILE}" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
    --build-arg VERSION="${IMAGE_TAG}" \
    "${BUILD_CONTEXT}"; then
    
    print_success "Docker image built successfully"
    
    # Show image details
    print_status "Image details:"
    docker images "${IMAGE_NAME}:${IMAGE_TAG}"
    
    # Show image size
    IMAGE_SIZE=$(docker images --format "table {{.Size}}" "${IMAGE_NAME}:${IMAGE_TAG}" | tail -n 1)
    print_status "Image size: ${IMAGE_SIZE}"
    
    # Show Harbor-tagged images
    print_status "Harbor-tagged images:"
    docker images "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}"
    
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Optional: Run security scan after build
if command -v trivy >/dev/null 2>&1; then
    print_status "Running security scan..."
    trivy image --severity HIGH,CRITICAL "${IMAGE_NAME}:${IMAGE_TAG}"
fi

print_success "Build completed successfully"