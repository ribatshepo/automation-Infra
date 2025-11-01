# main-python-deploy.yml Configuration Reference

## Overview
Complete list of all configurable GitHub variables for the Python FastAPI deployment workflow.

## Workflow Input Defaults
These variables control the default values for workflow inputs:

```yaml
# Environment Configuration
DEFAULT_ENVIRONMENT: "dev"                      # Default environment
DEFAULT_PYTHON_VERSION: "3.11"                 # Default Python version
```

## Build Configuration
Python build and test settings:

```yaml
# Python Settings
PYTHON_VERSION: "3.11"                         # Python version
PACKAGE_MANAGER: "pip"                         # Package manager (pip/poetry/pipenv)

# Build Options
RUN_TESTS: true                                 # Enable unit tests
RUN_LINTING: true                              # Enable linting (flake8, black, etc.)
SECURITY_SCAN_ENABLED: true                    # Enable security scanning
BUILD_DOCKER: true                             # Build Docker image
```

## Application Configuration
Core application settings:

```yaml
# Application Settings
APP_NAME: "fastapi-app"                        # Application name
APP_PORT: 8000                                 # Application port
SERVICE_TYPE: "ClusterIP"                      # Kubernetes service type
LOG_LEVEL: "info"                              # Application log level
```

## Deployment Configuration
Kubernetes deployment settings:

```yaml
# Namespace Configuration
NAMESPACE_PREFIX: "python-apps"                # Namespace prefix

# Replica Configuration
PROD_REPLICAS: 3                               # Production replica count
DEV_REPLICAS: 1                                # Development replica count

# Resource Configuration
PROD_MEMORY_REQUEST: "512Mi"                   # Prod memory request
DEV_MEMORY_REQUEST: "256Mi"                    # Dev memory request
PROD_CPU_REQUEST: "500m"                       # Prod CPU request
DEV_CPU_REQUEST: "250m"                        # Dev CPU request
PROD_MEMORY_LIMIT: "1Gi"                       # Prod memory limit
DEV_MEMORY_LIMIT: "512Mi"                      # Dev memory limit
PROD_CPU_LIMIT: "1000m"                        # Prod CPU limit
DEV_CPU_LIMIT: "500m"                          # Dev CPU limit
```

## Ingress Configuration
Networking and ingress settings:

```yaml
# Ingress Settings
INGRESS_ENABLED: true                          # Enable ingress
HEALTH_CHECK_PATH: "/health"                   # Health check endpoint
DEPLOY_TO_CLUSTER: true                        # Deploy to cluster

# Domain Settings
DOMAIN_SUFFIX: "mycompany.com"                 # Base domain for ingress
```

## Database Migration
Production database migration settings:

```yaml
# Migration Configuration
RUNNER_TYPE: "ubuntu-latest"                   # GitHub runner type
PROD_ENVIRONMENT_NAME: "production"            # GitHub environment name
REQUIREMENTS_FILE: "requirements.txt"          # Requirements file path
MIGRATION_COMMAND: "alembic upgrade head"      # Migration command
```

## Required Secrets
These secrets must be configured in GitHub:

```yaml
# Harbor Registry
HARBOR_REGISTRY: "harbor.mycompany.com"
HARBOR_USERNAME: "robot$my-project"
HARBOR_PASSWORD: "generated-token"
HARBOR_PROJECT: "my-project"

# Artifactory (Optional)
ARTIFACTORY_URL: "https://artifactory.mycompany.com"
ARTIFACTORY_USERNAME: "build-user"
ARTIFACTORY_PASSWORD: "build-token"

# Kubernetes
KUBECONFIG: "base64-encoded-kubeconfig"

# Database
DATABASE_URL: "postgresql://user:pass@host:5432/dbname"
REDIS_URL: "redis://redis-host:6379/0"
DATABASE_CONNECTION_STRING: "connection-string-for-migrations"
```

## Example Configuration
Complete example for a FastAPI application:

```yaml
# GitHub Repository Variables
PYTHON_VERSION: "3.11"
APP_NAME: "my-fastapi-app"
APP_PORT: 8000
NAMESPACE_PREFIX: "backend-services"
PROD_REPLICAS: 5
DEV_REPLICAS: 2
LOG_LEVEL: "info"
DOMAIN_SUFFIX: "api.mycompany.com"
MIGRATION_COMMAND: "python manage.py migrate"
REQUIREMENTS_FILE: "requirements/production.txt"
```

## Usage Notes
- Supports pip, poetry, and pipenv package managers
- Database migrations only run for production deployments
- ConfigMap includes database and Redis URLs from secrets
- Namespace follows pattern: `{NAMESPACE_PREFIX}-{environment}`
- Health check endpoint is configurable for different FastAPI setups