# main-nodejs-deploy.yml Configuration Reference

## Overview
Complete list of all configurable GitHub variables for the Node.js deployment workflow.

## Workflow Input Defaults
These variables control the default values for workflow inputs:

```yaml
# Environment Configuration
DEFAULT_ENVIRONMENT: "dev"                      # Default environment
```

## Build Configuration
Node.js build and test settings:

```yaml
# Node.js Settings
NODE_VERSION: "20"                              # Node.js version
PACKAGE_MANAGER: "npm"                          # Package manager (npm/yarn/pnpm)

# Build Options
RUN_TESTS: true                                 # Enable unit tests
RUN_E2E_TESTS: true                            # Enable E2E tests
SECURITY_SCAN_ENABLED: true                    # Enable security scanning
BUILD_DOCKER: true                             # Build Docker image
```

## Application Configuration
Core application settings:

```yaml
# Application Settings
APP_NAME: "nodejs-app"                         # Application name
APP_PORT: 3000                                 # Application port
DOCKERFILE_PATH: "./Dockerfile"                # Path to Dockerfile
BUILD_CONTEXT: "."                             # Docker build context
```

## Deployment Configuration
Kubernetes deployment settings:

```yaml
# Namespace Configuration
PROD_NAMESPACE: "production"                   # Production namespace
DEV_NAMESPACE: "development"                   # Development namespace

# Replica Configuration
PROD_REPLICAS: 5                               # Production replica count
DEV_REPLICAS: 2                                # Development replica count

# Feature Flags
INGRESS_ENABLED: true                          # Enable ingress
DEPLOY_TO_K8S: true                            # Deploy to Kubernetes
```

## Domain Configuration
DNS and ingress settings:

```yaml
# Domain Settings
DOMAIN_SUFFIX: "mycompany.com"                 # Base domain for ingress
```

## Performance Testing
Load testing configuration:

```yaml
# Performance Testing
PERFORMANCE_TEST_ENVIRONMENT: "production"     # Target environment
PERFORMANCE_TEST_SCRIPT: "performance-tests.js" # Test script path
PERFORMANCE_TEST_ARTIFACT_NAME: "performance-test-results" # Artifact name
PERFORMANCE_TEST_RESULTS_PATH: "test-results/" # Results directory
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
```

## Example Configuration
Complete example for a Node.js application:

```yaml
# GitHub Repository Variables
NODE_VERSION: "18"
APP_NAME: "my-nodejs-app"
APP_PORT: 8080
PROD_REPLICAS: 3
DEV_REPLICAS: 1
DOMAIN_SUFFIX: "example.io"
RUN_E2E_TESTS: true
PERFORMANCE_TEST_SCRIPT: "k6-performance.js"
```

## Usage Notes
- Supports npm, yarn, and pnpm package managers
- E2E tests only run on main branch by default
- Performance tests only run for production deployments
- All variables have sensible defaults for quick setup