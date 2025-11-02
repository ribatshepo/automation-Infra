#!/bin/bash

# Docker Clean Script

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

CLEAN_TYPE=${1:-"containers"}
PROJECT_NAME=${2:-$(basename "$(pwd)")}

case $CLEAN_TYPE in
    "containers"|"c")
        print_status "Cleaning containers for project: $PROJECT_NAME"
        docker-compose --project-name "$PROJECT_NAME" down --remove-orphans
        docker container prune -f
        ;;
    "images"|"i")
        print_status "Cleaning images..."
        docker image prune -f
        print_status "Cleaning dangling images..."
        docker images -f "dangling=true" -q | xargs -r docker rmi
        ;;
    "volumes"|"v")
        print_status "Cleaning volumes..."
        docker volume prune -f
        ;;
    "networks"|"n")
        print_status "Cleaning networks..."
        docker network prune -f
        ;;
    "project"|"p")
        print_status "Cleaning all project resources: $PROJECT_NAME"
        docker-compose --project-name "$PROJECT_NAME" down --remove-orphans --volumes
        docker system prune -f
        ;;
    "all"|"a")
        print_warning "This will remove ALL Docker resources"
        read -p "Are you sure? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            print_status "Cleaning everything..."
            docker-compose --project-name "$PROJECT_NAME" down --remove-orphans --volumes
            docker system prune -a -f --volumes
        else
            print_status "Cleanup cancelled"
            exit 0
        fi
        ;;
    "cache"|"cache")
        print_status "Cleaning build cache..."
        docker builder prune -f
        ;;
    *)
        echo "Docker Clean Script"
        echo
        echo "Usage: $0 <type> [project_name]"
        echo
        echo "Clean Types:"
        echo "  containers (c) - Remove containers and orphans"
        echo "  images (i)     - Remove unused images"
        echo "  volumes (v)    - Remove unused volumes"
        echo "  networks (n)   - Remove unused networks"
        echo "  project (p)    - Remove all project resources"
        echo "  cache          - Remove build cache"
        echo "  all (a)        - Remove everything (WARNING!)"
        echo
        echo "Examples:"
        echo "  $0 containers"
        echo "  $0 images"
        echo "  $0 project my-app"
        echo "  $0 all"
        exit 1
        ;;
esac

print_success "Cleanup completed"