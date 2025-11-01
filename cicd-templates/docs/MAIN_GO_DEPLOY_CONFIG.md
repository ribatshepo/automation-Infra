# main-go-deploy.yml Configuration Reference

## Overview
Complete list of all configurable GitHub variables for the Go microservice deployment workflow.

## Workflow Input Defaults
These variables control the default values for workflow inputs:

```yaml
# Environment Configuration
DEFAULT_ENVIRONMENT: "dev"                      # Default environment
```

## Build Configuration
Go build and test settings:

```yaml
# Go Settings
GO_VERSION: "1.21"                             # Go version

# Build Options
RUN_TESTS: true                                 # Enable unit tests
RUN_BENCHMARKS: true                           # Enable benchmarks
SECURITY_SCAN_ENABLED: true                    # Enable security scanning
BUILD_DOCKER: true                             # Build Docker image
CROSS_COMPILE: true                            # Enable cross-compilation
```

## Application Configuration
Core application settings:

```yaml
# Application Settings
APP_PORT: 8080                                 # Application port
HEALTH_CHECK_PATH: "/health"                   # Health check endpoint
API_PATH: "/api/v1"                           # API base path
```

## Deployment Configuration
Helm deployment settings:

```yaml
# Helm Configuration
HELM_CHART_PATH: "./helm-charts/app-template"  # Helm chart path
PR_DRY_RUN: true                               # Dry run for PRs

# Namespace Configuration
NAMESPACE_PREFIX: "microservices"              # Namespace prefix

# Replica Configuration
PROD_REPLICAS: 5                               # Production replica count
DEV_REPLICAS: 2                                # Development replica count
```

## Resource Allocation
Environment-specific resource limits:

```yaml
# Resource Configuration
PROD_MEMORY_REQUEST: "256Mi"                   # Prod memory request
DEV_MEMORY_REQUEST: "128Mi"                    # Dev memory request
PROD_CPU_REQUEST: "250m"                       # Prod CPU request
DEV_CPU_REQUEST: "100m"                        # Dev CPU request
PROD_MEMORY_LIMIT: "512Mi"                     # Prod memory limit
DEV_MEMORY_LIMIT: "256Mi"                      # Dev memory limit
PROD_CPU_LIMIT: "1000m"                        # Prod CPU limit
DEV_CPU_LIMIT: "500m"                          # Dev CPU limit
```

## Auto-scaling Configuration
Horizontal Pod Autoscaler settings:

```yaml
# Auto-scaling
AUTOSCALING_ENABLED: true                      # Enable auto-scaling
PROD_MIN_REPLICAS: 3                          # Prod min replicas
DEV_MIN_REPLICAS: 1                           # Dev min replicas
PROD_MAX_REPLICAS: 10                         # Prod max replicas
DEV_MAX_REPLICAS: 5                           # Dev max replicas
CPU_TARGET_PERCENTAGE: 70                     # CPU target for scaling
```

## Ingress Configuration
Networking and ingress settings:

```yaml
# Ingress Settings
INGRESS_ENABLED: true                          # Enable ingress
INGRESS_PATH_TYPE: "Prefix"                    # Ingress path type

# Domain Settings
DOMAIN_SUFFIX: "mycompany.com"                 # Base domain for ingress
```

## Environment Variables
Application runtime configuration:

```yaml
# Runtime Environment
PROD_GO_ENV: "production"                      # Production Go environment
DEV_GO_ENV: "development"                      # Development Go environment
PROD_LOG_LEVEL: "info"                        # Production log level
DEV_LOG_LEVEL: "debug"                        # Development log level

# Feature Configuration
CONFIG_MAP_ENABLED: true                       # Enable config map
FEATURE_FLAGS: '{"new_api": true, "metrics": true}' # Feature flags JSON
TIMEOUT_SECONDS: "30"                         # Request timeout
```

## Integration Testing
Test configuration settings:

```yaml
# Test Configuration
RUNNER_TYPE: "ubuntu-latest"                   # GitHub runner type
INTEGRATION_TEST_PACKAGE: "./tests/integration/..." # Test package path
TEST_TIMEOUT: "10m"                           # Test timeout
INTEGRATION_TEST_ARTIFACT_NAME: "integration-test-results" # Artifact name
TEST_RESULTS_PATH: "test-results.xml"         # Test results file
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
Complete example for a Go microservice:

```yaml
# GitHub Repository Variables
GO_VERSION: "1.21"
APP_PORT: 8080
NAMESPACE_PREFIX: "backend-services"
PROD_REPLICAS: 3
DEV_REPLICAS: 1
API_PATH: "/api/v2"
DOMAIN_SUFFIX: "api.mycompany.com"
RUN_BENCHMARKS: true
FEATURE_FLAGS: '{"metrics": true, "tracing": true}'
INTEGRATION_TEST_PACKAGE: "./tests/integration/..."
```

## Usage Notes
- Benchmarks only run on main branch by default
- Integration tests run against deployed service
- ConfigMap includes feature flags and timeout configuration
- Namespace follows pattern: `{NAMESPACE_PREFIX}-{environment}`
- Cross-compilation is enabled for multi-platform builds