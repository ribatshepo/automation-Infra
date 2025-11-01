# main-dotnet-deploy.yml Configuration Reference

## Overview
Complete list of all configurable GitHub variables for the .NET Web API deployment workflow.

## Workflow Input Defaults
These variables control the default values for workflow inputs:

```yaml
# Environment Configuration
DEFAULT_ENVIRONMENT: "dev"                      # Default environment
DEFAULT_DEPLOY_TO_K8S: true                    # Default Kubernetes deployment
```

## Build Configuration
.NET build and test settings:

```yaml
# .NET Settings
TARGET_FRAMEWORK: "net8.0"                     # Target framework

# Build Configuration
PROD_BUILD_CONFIG: "Release"                   # Production build config
DEV_BUILD_CONFIG: "Debug"                     # Development build config

# Build Options
RUN_TESTS: true                                # Enable unit tests
SECURITY_SCAN_ENABLED: true                   # Enable security scanning
```

## Application Configuration
Core application settings:

```yaml
# Application Settings
APP_PORT: 5000                                # Application port
HEALTH_CHECK_PATH: "/health"                  # Health check endpoint
```

## Deployment Configuration
Helm deployment settings:

```yaml
# Helm Configuration
HELM_CHART_PATH: "./helm-charts/app-template"  # Helm chart path
PR_DRY_RUN: true                              # Dry run for PRs

# Namespace Configuration
PROD_NAMESPACE: "production"                   # Production namespace
DEV_NAMESPACE: "development"                   # Development namespace
```

## Resource Allocation
Environment-specific resource limits:

```yaml
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
INGRESS_PATH: "/"                              # Ingress path
INGRESS_PATH_TYPE: "Prefix"                    # Ingress path type

# Domain Settings
DOMAIN_SUFFIX: "mycompany.com"                 # Base domain for ingress
```

## Environment Variables
ASP.NET Core runtime configuration:

```yaml
# Runtime Environment
PROD_ASPNETCORE_ENV: "Production"              # Production ASP.NET environment
DEV_ASPNETCORE_ENV: "Development"              # Development ASP.NET environment
```

## Notification Configuration
Deployment notification settings:

```yaml
# Infrastructure
RUNNER_TYPE: "ubuntu-latest"                   # GitHub runner type
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
DATABASE_CONNECTION_STRING: "Server=localhost;Database=myapp;Trusted_Connection=true;"
```

## Example Configuration
Complete example for a .NET Web API:

```yaml
# GitHub Repository Variables
TARGET_FRAMEWORK: "net8.0"
APP_PORT: 8080
PROD_NAMESPACE: "backend-production"
DEV_NAMESPACE: "backend-development"
PROD_MEMORY_REQUEST: "512Mi"
PROD_CPU_REQUEST: "500m"
DOMAIN_SUFFIX: "api.mycompany.com"
HEALTH_CHECK_PATH: "/health/ready"
INGRESS_PATH: "/api"
```

## Usage Notes
- Build configuration automatically switches between Debug/Release based on environment
- Supports .NET 6, 7, 8+ frameworks
- Namespace pattern: `{PROD_NAMESPACE}` or `{DEV_NAMESPACE}`
- ASP.NET Core environment variables are automatically configured
- Database connection string is injected from secrets