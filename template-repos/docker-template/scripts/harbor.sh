#!/bin/bash

# Harbor Integration Script
# Manages Harbor registry operations

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
HARBOR_URL=${HARBOR_URL:-"harbor.local"}
PROJECT_NAME=${HARBOR_PROJECT:-"library"}
IMAGE_NAME=${1:-$(basename "$(pwd)")}
IMAGE_TAG=${2:-"latest"}

# Harbor API configuration
HARBOR_API="${HARBOR_URL}/api/v2.0"

# Function to check Harbor authentication
check_harbor_auth() {
    print_status "Checking Harbor authentication..."
    
    if [[ -z "${HARBOR_USERNAME:-}" ]] || [[ -z "${HARBOR_PASSWORD:-}" ]]; then
        print_error "Harbor credentials not set"
        echo "Set environment variables:"
        echo "  export HARBOR_USERNAME=your_username"
        echo "  export HARBOR_PASSWORD=your_password"
        exit 1
    fi
    
    # Test authentication
    if curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        "${HARBOR_API}/users/current" > /dev/null; then
        print_success "Harbor authentication successful"
    else
        print_error "Harbor authentication failed"
        exit 1
    fi
}

# Function to create Harbor project if it doesn't exist
create_harbor_project() {
    local project_name=$1
    
    print_status "Checking if Harbor project '${project_name}' exists..."
    
    # Check if project exists
    if curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        "${HARBOR_API}/projects/${project_name}" > /dev/null 2>&1; then
        print_success "Harbor project '${project_name}' already exists"
        return 0
    fi
    
    print_status "Creating Harbor project '${project_name}'..."
    
    # Create project
    local project_data=$(cat <<EOF
{
    "project_name": "${project_name}",
    "public": false,
    "metadata": {
        "auto_scan": "true",
        "severity": "high",
        "reuse_sys_cve_allowlist": "true"
    }
}
EOF
    )
    
    if curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "${project_data}" \
        "${HARBOR_API}/projects"; then
        print_success "Harbor project '${project_name}' created successfully"
    else
        print_error "Failed to create Harbor project '${project_name}'"
        exit 1
    fi
}

# Function to push image to Harbor
push_to_harbor() {
    local image_name=$1
    local image_tag=$2
    
    print_status "Pushing image to Harbor..."
    
    local local_image="${image_name}:${image_tag}"
    local harbor_image="${HARBOR_URL}/${PROJECT_NAME}/${image_name}:${image_tag}"
    
    # Tag image for Harbor
    if docker tag "${local_image}" "${harbor_image}"; then
        print_success "Image tagged for Harbor: ${harbor_image}"
    else
        print_error "Failed to tag image for Harbor"
        exit 1
    fi
    
    # Login to Harbor
    if echo "${HARBOR_PASSWORD}" | docker login "${HARBOR_URL}" \
        --username "${HARBOR_USERNAME}" --password-stdin; then
        print_success "Docker login to Harbor successful"
    else
        print_error "Docker login to Harbor failed"
        exit 1
    fi
    
    # Push image
    if docker push "${harbor_image}"; then
        print_success "Image pushed to Harbor: ${harbor_image}"
    else
        print_error "Failed to push image to Harbor"
        exit 1
    fi
}

# Function to scan image in Harbor
scan_image() {
    local image_name=$1
    local image_tag=$2
    
    print_status "Triggering Harbor vulnerability scan..."
    
    # Trigger scan
    if curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        -X POST \
        "${HARBOR_API}/projects/${PROJECT_NAME}/repositories/${image_name}/artifacts/${image_tag}/scan"; then
        print_success "Harbor vulnerability scan triggered"
    else
        print_warning "Failed to trigger Harbor vulnerability scan"
    fi
    
    # Wait a moment for scan to start
    sleep 5
    
    # Get scan results
    print_status "Checking scan results..."
    local scan_result=$(curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        "${HARBOR_API}/projects/${PROJECT_NAME}/repositories/${image_name}/artifacts/${image_tag}")
    
    if echo "${scan_result}" | grep -q "scan_overview"; then
        print_status "Scan results available"
        # Parse and display results
        echo "${scan_result}" | jq '.scan_overview' 2>/dev/null || echo "Scan in progress..."
    else
        print_status "Scan still in progress"
    fi
}

# Function to list images in Harbor project
list_images() {
    print_status "Listing images in Harbor project '${PROJECT_NAME}'..."
    
    local images=$(curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        "${HARBOR_API}/projects/${PROJECT_NAME}/repositories")
    
    if echo "${images}" | jq -r '.[].name' 2>/dev/null; then
        print_success "Images listed successfully"
    else
        print_warning "No images found or failed to retrieve images"
    fi
}

# Function to delete image from Harbor
delete_image() {
    local image_name=$1
    local image_tag=$2
    
    print_warning "Deleting image from Harbor: ${PROJECT_NAME}/${image_name}:${image_tag}"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
            -X DELETE \
            "${HARBOR_API}/projects/${PROJECT_NAME}/repositories/${image_name}/artifacts/${image_tag}"; then
            print_success "Image deleted from Harbor"
        else
            print_error "Failed to delete image from Harbor"
            exit 1
        fi
    else
        print_status "Image deletion cancelled"
    fi
}

# Function to show Harbor project quotas
show_quotas() {
    print_status "Showing Harbor project quotas for '${PROJECT_NAME}'..."
    
    local quotas=$(curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        "${HARBOR_API}/quotas?reference=project&reference_id=${PROJECT_NAME}")
    
    if echo "${quotas}" | jq '.' 2>/dev/null; then
        print_success "Quotas retrieved successfully"
    else
        print_warning "Failed to retrieve quotas"
    fi
}

# Function to configure Harbor webhook
configure_webhook() {
    local webhook_url=$1
    
    print_status "Configuring Harbor webhook..."
    
    local webhook_data=$(cat <<EOF
{
    "name": "ci-cd-webhook",
    "description": "CI/CD webhook for ${PROJECT_NAME}",
    "targets": [{
        "type": "http",
        "address": "${webhook_url}",
        "skip_cert_verify": false
    }],
    "event_types": [
        "PUSH_ARTIFACT",
        "PULL_ARTIFACT",
        "DELETE_ARTIFACT",
        "SCANNING_FAILED",
        "SCANNING_COMPLETED"
    ],
    "enabled": true
}
EOF
    )
    
    if curl -s -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "${webhook_data}" \
        "${HARBOR_API}/projects/${PROJECT_NAME}/webhook/policies"; then
        print_success "Harbor webhook configured successfully"
    else
        print_error "Failed to configure Harbor webhook"
    fi
}

# Main function
main() {
    local action=${1:-"help"}
    
    case $action in
        "auth"|"check-auth")
            check_harbor_auth
            ;;
        "create-project")
            check_harbor_auth
            create_harbor_project "${PROJECT_NAME}"
            ;;
        "push")
            check_harbor_auth
            create_harbor_project "${PROJECT_NAME}"
            push_to_harbor "${IMAGE_NAME}" "${IMAGE_TAG}"
            ;;
        "scan")
            check_harbor_auth
            scan_image "${IMAGE_NAME}" "${IMAGE_TAG}"
            ;;
        "list")
            check_harbor_auth
            list_images
            ;;
        "delete")
            check_harbor_auth
            delete_image "${IMAGE_NAME}" "${IMAGE_TAG}"
            ;;
        "quotas")
            check_harbor_auth
            show_quotas
            ;;
        "webhook")
            local webhook_url=${2:-""}
            if [[ -z "$webhook_url" ]]; then
                print_error "Webhook URL required"
                echo "Usage: $0 webhook <webhook_url>"
                exit 1
            fi
            check_harbor_auth
            configure_webhook "$webhook_url"
            ;;
        "full-deploy")
            check_harbor_auth
            create_harbor_project "${PROJECT_NAME}"
            push_to_harbor "${IMAGE_NAME}" "${IMAGE_TAG}"
            scan_image "${IMAGE_NAME}" "${IMAGE_TAG}"
            ;;
        "help"|*)
            echo "Harbor Integration Script"
            echo
            echo "Usage: $0 <action> [options]"
            echo
            echo "Actions:"
            echo "  auth             - Check Harbor authentication"
            echo "  create-project   - Create Harbor project"
            echo "  push             - Push image to Harbor"
            echo "  scan             - Trigger vulnerability scan"
            echo "  list             - List images in project"
            echo "  delete           - Delete image from Harbor"
            echo "  quotas           - Show project quotas"
            echo "  webhook <url>    - Configure webhook"
            echo "  full-deploy      - Complete deployment workflow"
            echo "  help             - Show this help"
            echo
            echo "Environment Variables:"
            echo "  HARBOR_URL       - Harbor URL (default: harbor.local)"
            echo "  HARBOR_USERNAME  - Harbor username"
            echo "  HARBOR_PASSWORD  - Harbor password"
            echo "  HARBOR_PROJECT   - Harbor project (default: library)"
            echo
            echo "Examples:"
            echo "  $0 auth"
            echo "  $0 push my-app latest"
            echo "  $0 scan my-app latest"
            echo "  $0 full-deploy my-app v1.0.0"
            ;;
    esac
}

# Run main function
main "$@"