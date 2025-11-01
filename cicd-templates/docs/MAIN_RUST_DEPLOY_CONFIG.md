# main-rust-deploy.yml Configuration Reference

## Overview
Complete list of all configurable GitHub variables for the Rust web service deployment workflow.

## Workflow Input Defaults
These variables control the default values for workflow inputs:

```yaml
# Environment Configuration
DEFAULT_ENVIRONMENT: "dev"                      # Default environment
```

## Build Configuration
Rust build and test settings:

```yaml
# Rust Settings
RUST_VERSION: "stable"                         # Rust version (stable, beta, nightly)

# Build Options
RUN_TESTS: true                                # Enable unit tests
RUN_CLIPPY: true                              # Enable Clippy linting
SECURITY_SCAN_ENABLED: true                   # Enable security scanning
BUILD_DOCKER: true                            # Build Docker image
CROSS_COMPILE: true                           # Enable cross-compilation
```

## Application Configuration
Core application settings:

```yaml
# Application Settings
APP_NAME: "rust-web-service"                  # Application name
APP_PORT: 8080                                # Application port
HEALTH_CHECK_PATH: "/health"                  # Health check endpoint
```

## Deployment Configuration
Kubernetes and Helm deployment settings:

```yaml
# Namespace Configuration
NAMESPACE_PREFIX: "rust-services"             # Namespace prefix

# Staging Configuration
STAGING_REPLICAS: 2                           # Staging replica count

# Production Configuration
PROD_REPLICAS: 5                              # Production replica count

# Helm Configuration
HELM_CHART_PATH: "./helm-charts/app-template"  # Helm chart path
HELM_DRY_RUN: false                           # Helm dry run mode
HELM_WAIT: true                               # Wait for deployment
DEPLOY_TIMEOUT: 15                            # Deployment timeout (minutes)
```

## Resource Allocation
Environment-specific resource limits:

```yaml
# Staging Resources
STAGING_MEMORY_REQUEST: "128Mi"               # Staging memory request
STAGING_CPU_REQUEST: "100m"                   # Staging CPU request
STAGING_MEMORY_LIMIT: "256Mi"                 # Staging memory limit
STAGING_CPU_LIMIT: "500m"                     # Staging CPU limit

# Production Resources
PROD_MEMORY_REQUEST: "256Mi"                  # Prod memory request
PROD_CPU_REQUEST: "250m"                      # Prod CPU request
PROD_MEMORY_LIMIT: "512Mi"                    # Prod memory limit
PROD_CPU_LIMIT: "1000m"                       # Prod CPU limit
```

## Auto-scaling Configuration
Horizontal Pod Autoscaler settings:

```yaml
# Auto-scaling
AUTOSCALING_ENABLED: true                     # Enable auto-scaling
PROD_MIN_REPLICAS: 3                         # Prod min replicas
PROD_MAX_REPLICAS: 10                        # Prod max replicas
CPU_TARGET_PERCENTAGE: 70                    # CPU target for scaling
MEMORY_TARGET_PERCENTAGE: 80                 # Memory target for scaling
```

## Ingress Configuration
Networking and ingress settings:

```yaml
# Ingress Settings
INGRESS_ENABLED: true                         # Enable ingress
INGRESS_CLASS: "nginx"                        # Ingress class
CERT_ISSUER: "letsencrypt-prod"              # Certificate issuer
RATE_LIMIT: "100"                            # Rate limit

# Domain Settings
DOMAIN_SUFFIX: "mycompany.com"                # Base domain for ingress
```

## Environment Variables
Rust application runtime configuration:

```yaml
# Runtime Environment
RUST_ENV: "production"                        # Rust environment
RUST_LOG_LEVEL: "info"                       # Rust log level

# Monitoring
MONITORING_ENABLED: true                      # Enable monitoring
PROMETHEUS_SCRAPE: "true"                     # Prometheus scraping
PROMETHEUS_PORT: "8080"                       # Prometheus port
PROMETHEUS_PATH: "/metrics"                   # Prometheus metrics path
```

## Load Testing Configuration
k6 load testing settings:

```yaml
# Load Testing
LOAD_TEST_VUS: 50                             # Virtual users for load test
LOAD_TEST_DURATION: "5m"                     # Load test duration
LOAD_TEST_ARTIFACT_NAME: "load-test-results" # Artifact name
LOAD_TEST_RESULTS_PATH: "test-results/"      # Results directory

# k6 Installation
K6_GPG_KEY: "C5AD17C747E3415A3642D57D77C6C491D6AC1D69" # k6 GPG key
K6_REPO: "https://dl.k6.io/deb"              # k6 repository URL

# Infrastructure
RUNNER_TYPE: "ubuntu-latest"                  # GitHub runner type
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
STAGING_KUBECONFIG: "base64-encoded-staging-kubeconfig"
```

## Example Configuration
Complete example for a Rust web service:

```yaml
# GitHub Repository Variables
RUST_VERSION: "1.75"
APP_NAME: "my-rust-service"
APP_PORT: 8080
NAMESPACE_PREFIX: "backend-services"
PROD_REPLICAS: 3
STAGING_REPLICAS: 1
DOMAIN_SUFFIX: "api.mycompany.com"
RUST_LOG_LEVEL: "info"
LOAD_TEST_VUS: 100
LOAD_TEST_DURATION: "10m"
MONITORING_ENABLED: true
CERT_ISSUER: "letsencrypt-staging"
```

## Usage Notes
- Supports stable, beta, and nightly Rust channels
- Staging deployment triggers on develop branch
- Production deployment triggers on main branch
- Load testing only runs for production deployments
- Namespace follows pattern: `{NAMESPACE_PREFIX}-{environment}`
- Clippy linting and security scanning are enabled by default
- Cross-compilation supports multiple architectures