# main-docker-deploy.yml Configuration Reference

## Overview
Complete list of all configurable GitHub variables for the Docker deployment workflow.

## Workflow Input Defaults
These variables control the default values for workflow inputs:

```yaml
# Environment & Domain Configuration
DEFAULT_DOMAIN_SUFFIX: "mycompany.com"           # Default domain suffix
DEFAULT_HELM_CHART_PATH: "./charts/my-app"       # Default Helm chart path
DEFAULT_BUILD_PLATFORM: "linux/amd64"            # Default build platforms

# File Paths
DOCKERFILE_PATH: "./Dockerfile"                   # Path to Dockerfile
BUILD_CONTEXT: "."                               # Docker build context
HELM_CHART_PATH: "./helm-charts/app-template"    # Helm chart location
HELM_VALUES_FILE_TEMPLATE: "./helm/values-{0}.yaml"  # Values file pattern
```

## Build Configuration
Control Docker build process:

```yaml
# Build Settings
BUILD_PLATFORMS: "linux/amd64,linux/arm64"       # Multi-platform builds
SECURITY_SCAN_ENABLED: true                      # Enable security scanning
PUSH_LATEST: true                                # Push latest tag

# Build Arguments
PROD_NODE_ENV: "production"                      # Production Node environment
DEV_NODE_ENV: "development"                     # Development Node environment
```

## Application Configuration
Core application settings:

```yaml
# Application Settings
APP_PORT: 8080                                   # Application port
APP_NAME: "my-docker-app"                       # Application name override
HEALTH_CHECK_PATH: "/health"                     # Health check endpoint
API_HEALTH_PATH: "/api/health"                   # API health endpoint
```

## Resource Allocation
Environment-specific resource limits:

```yaml
# Development Environment
DEV_REPLICAS: 1                                  # Dev replica count
DEV_MEMORY_REQUEST: "128Mi"                      # Dev memory request
DEV_CPU_REQUEST: "100m"                         # Dev CPU request
DEV_MEMORY_LIMIT: "256Mi"                       # Dev memory limit
DEV_CPU_LIMIT: "200m"                           # Dev CPU limit
DEV_SERVICE_TYPE: "NodePort"                    # Dev service type

# Staging Environment
STAGING_REPLICAS: 2                             # Staging replica count
STAGING_MIN_REPLICAS: 1                         # Staging min replicas
STAGING_MAX_REPLICAS: 5                         # Staging max replicas
STAGING_MEMORY_REQUEST: "256Mi"                 # Staging memory request
STAGING_CPU_REQUEST: "250m"                     # Staging CPU request
STAGING_MEMORY_LIMIT: "512Mi"                  # Staging memory limit
STAGING_CPU_LIMIT: "500m"                      # Staging CPU limit
STAGING_LOG_LEVEL: "debug"                     # Staging log level
STAGING_NODE_ENV: "staging"                    # Staging Node environment
STAGING_MAX_CONN: 100                          # Staging max connections

# Production Environment
PROD_REPLICAS: 5                                # Prod replica count
PROD_MIN_REPLICAS: 3                           # Prod min replicas
PROD_MAX_REPLICAS: 15                          # Prod max replicas
PROD_MEMORY_REQUEST: "512Mi"                   # Prod memory request
PROD_CPU_REQUEST: "500m"                       # Prod CPU request
PROD_MEMORY_LIMIT: "1Gi"                       # Prod memory limit
PROD_CPU_LIMIT: "1000m"                        # Prod CPU limit
PROD_LOG_LEVEL: "info"                         # Prod log level
PROD_NODE_ENV: "production"                    # Prod Node environment
PROD_MAX_CONN: 1000                            # Prod max connections
```

## Auto-scaling Configuration
Horizontal Pod Autoscaler settings:

```yaml
# Auto-scaling
AUTOSCALING_ENABLED: true                       # Enable auto-scaling
```

## Ingress Configuration
Ingress and networking settings:

```yaml
# Ingress Settings
INGRESS_ENABLED: true                           # Enable ingress
INGRESS_PATH: "/"                               # Ingress path
INGRESS_PATH_TYPE: "Prefix"                     # Path type
```

## Helm Configuration
Helm deployment settings:

```yaml
# Helm Settings
HELM_DRY_RUN: false                             # Helm dry run mode
HELM_UPGRADE: true                              # Enable Helm upgrade
HELM_WAIT: true                                 # Wait for deployment
DEPLOY_TIMEOUT: 10                              # Deployment timeout (minutes)
```

## Feature Toggles
Application feature configuration:

```yaml
# Feature Flags
CONFIG_MAP_ENABLED: true                        # Enable config map
ANALYTICS_ENABLED: true                         # Enable analytics
DEBUG_ENABLED: true                             # Enable debugging
MONITORING_ENABLED: true                        # Enable monitoring
METRICS_ENABLED: true                           # Enable metrics
```

## Performance & Limits
Application performance settings:

```yaml
# Performance Settings
REQUEST_TIMEOUT: 30                             # Request timeout (seconds)
```

## Smoke Testing Configuration
Post-deployment verification:

```yaml
# Test Configuration
RUNNER_TYPE: "ubuntu-latest"                    # GitHub runner type
HEALTH_CHECK_RETRIES: 5                        # Health check retry count
HEALTH_CHECK_INTERVAL: 30                      # Health check interval (seconds)

# Protocol Configuration
DEV_PROTOCOL: "http"                           # Dev protocol
DEV_SUBDOMAIN: "dev"                           # Dev subdomain
STAGING_PROTOCOL: "https"                     # Staging protocol
STAGING_SUBDOMAIN: "staging"                  # Staging subdomain
PROD_PROTOCOL: "https"                        # Prod protocol
```

## Required Secrets
These secrets must be configured in GitHub:

```yaml
# Harbor Registry
HARBOR_REGISTRY: "harbor.mycompany.com"
HARBOR_USERNAME: "robot$my-project"
HARBOR_PASSWORD: "generated-token"
HARBOR_PROJECT: "my-project"

# Kubernetes
KUBECONFIG: "base64-encoded-kubeconfig"
DEV_KUBECONFIG: "base64-encoded-dev-kubeconfig"
STAGING_KUBECONFIG: "base64-encoded-staging-kubeconfig"
```

## Example Configuration
Complete example for a typical setup:

```yaml
# GitHub Repository Variables
APP_PORT: 3000
DOMAIN_SUFFIX: "mycompany.io"
DEV_REPLICAS: 1
STAGING_REPLICAS: 2
PROD_REPLICAS: 5
HEALTH_CHECK_PATH: "/api/health"
MONITORING_ENABLED: true
INGRESS_ENABLED: true
```

## Usage Notes
- All variables have sensible defaults
- Override any value by setting the corresponding GitHub repository variable
- Environment-specific variables take precedence over generic ones
- Boolean values should be set as strings: "true" or "false"