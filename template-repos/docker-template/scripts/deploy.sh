#!/bin/bash

# Docker Deploy Script

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
ENVIRONMENT=${1:-"development"}
COMPOSE_FILE=""
COMPOSE_PROJECT_NAME=${2:-$(basename "$(pwd)")}

case $ENVIRONMENT in
    "development"|"dev")
        COMPOSE_FILE="docker-compose.dev.yml"
        ;;
    "production"|"prod")
        COMPOSE_FILE="docker-compose.yml"
        ;;
    "staging")
        COMPOSE_FILE="docker-compose.staging.yml"
        if [[ ! -f $COMPOSE_FILE ]]; then
            print_warning "Staging compose file not found, using production"
            COMPOSE_FILE="docker-compose.yml"
        fi
        ;;
    *)
        print_error "Unknown environment: $ENVIRONMENT"
        echo "Usage: $0 [development|staging|production] [project_name]"
        exit 1
        ;;
esac

print_status "Deploying to $ENVIRONMENT environment..."
print_status "Using compose file: $COMPOSE_FILE"
print_status "Project name: $COMPOSE_PROJECT_NAME"

# Check if compose file exists
if [[ ! -f $COMPOSE_FILE ]]; then
    print_error "Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Check environment file
ENV_FILE=".env"
if [[ $ENVIRONMENT == "production" || $ENVIRONMENT == "prod" ]]; then
    if [[ -f ".env.prod" ]]; then
        ENV_FILE=".env.prod"
        print_status "Using production environment file: $ENV_FILE"
    else
        print_warning "Production environment file (.env.prod) not found, using default .env"
    fi
elif [[ $ENVIRONMENT == "staging" ]]; then
    if [[ -f ".env.staging" ]]; then
        ENV_FILE=".env.staging"
        print_status "Using staging environment file: $ENV_FILE"
    fi
fi

# Validate environment file
if [[ ! -f $ENV_FILE ]]; then
    print_warning "Environment file not found: $ENV_FILE"
    if [[ -f ".env.example" ]]; then
        print_status "Creating $ENV_FILE from .env.example"
        cp .env.example $ENV_FILE
        print_warning "Please update $ENV_FILE with your configuration"
    fi
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose -f "$COMPOSE_FILE" --project-name "$COMPOSE_PROJECT_NAME" --env-file "$ENV_FILE" down --remove-orphans

# Pull latest images (for production/staging)
if [[ $ENVIRONMENT == "production" || $ENVIRONMENT == "prod" || $ENVIRONMENT == "staging" ]]; then
    print_status "Pulling latest images..."
    docker-compose -f "$COMPOSE_FILE" --project-name "$COMPOSE_PROJECT_NAME" --env-file "$ENV_FILE" pull
fi

# Build and start containers
print_status "Building and starting containers..."
if docker-compose -f "$COMPOSE_FILE" --project-name "$COMPOSE_PROJECT_NAME" --env-file "$ENV_FILE" up -d --build; then
    print_success "Deployment completed successfully"
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Show running containers
    print_status "Running containers:"
    docker-compose -f "$COMPOSE_FILE" --project-name "$COMPOSE_PROJECT_NAME" ps
    
    # Health checks
    print_status "Checking service health..."
    
    # Check app health
    if command -v curl >/dev/null 2>&1; then
        local max_attempts=30
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            if curl -f http://localhost:3000/health >/dev/null 2>&1; then
                print_success "Application is healthy"
                break
            else
                print_status "Waiting for application to be ready... (attempt $attempt/$max_attempts)"
                sleep 2
                ((attempt++))
            fi
        done
        
        if [[ $attempt -gt $max_attempts ]]; then
            print_warning "Application health check timed out"
        fi
    fi
    
    # Show recent logs
    print_status "Recent logs:"
    docker-compose -f "$COMPOSE_FILE" --project-name "$COMPOSE_PROJECT_NAME" logs --tail=10
    
    # Show access URLs
    print_status "Service URLs:"
    case $ENVIRONMENT in
        "development"|"dev")
            echo "  Application:     http://localhost:3000"
            echo "  Database Admin:  http://localhost:8080"
            echo "  Redis Commander: http://localhost:8081"
            echo "  Grafana:         http://localhost:3001"
            echo "  Prometheus:      http://localhost:9090"
            ;;
        "production"|"prod"|"staging")
            echo "  Application:     http://localhost"
            echo "  Grafana:         http://localhost:3001"
            echo "  Prometheus:      http://localhost:9090"
            ;;
    esac
    
else
    print_error "Deployment failed"
    print_status "Checking logs for errors..."
    docker-compose -f "$COMPOSE_FILE" --project-name "$COMPOSE_PROJECT_NAME" logs --tail=20
    exit 1
fi