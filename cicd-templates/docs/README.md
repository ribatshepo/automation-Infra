# Configuration Reference Index

This directory contains comprehensive configuration references for all CI/CD workflow templates.

## Configuration Files

###  [main-docker-deploy.yml](./MAIN_DOCKER_DEPLOY_CONFIG.md)
Complete Docker application deployment with multi-environment support.
- **Focus**: Docker builds, Harbor registry, Helm deployments
- **Features**: Multi-stage deployment, smoke testing, auto-scaling
- **Variables**: 40+ configurable settings

###  [main-nodejs-deploy.yml](./MAIN_NODEJS_DEPLOY_CONFIG.md)
Node.js application deployment with performance testing.
- **Focus**: Node.js builds, npm/yarn/pnpm support, full pipeline
- **Features**: E2E testing, performance testing, multiple environments
- **Variables**: 25+ configurable settings

###  [main-python-deploy.yml](./MAIN_PYTHON_DEPLOY_CONFIG.md)
Python FastAPI deployment with database migrations.
- **Focus**: Python builds, FastAPI, database integration
- **Features**: Database migrations, health checks, ConfigMap
- **Variables**: 30+ configurable settings

###  [main-go-deploy.yml](./MAIN_GO_DEPLOY_CONFIG.md)
Go microservice deployment with integration testing.
- **Focus**: Go builds, microservices, Helm charts
- **Features**: Benchmarks, integration tests, cross-compilation
- **Variables**: 35+ configurable settings

###  [main-dotnet-deploy.yml](./MAIN_DOTNET_DEPLOY_CONFIG.md)
.NET Web API deployment with ASP.NET Core configuration.
- **Focus**: .NET builds, ASP.NET Core, entity framework
- **Features**: Debug/Release builds, health checks, notifications
- **Variables**: 20+ configurable settings

###  [main-rust-deploy.yml](./MAIN_RUST_DEPLOY_CONFIG.md)
Rust web service deployment with load testing.
- **Focus**: Rust builds, performance optimization, monitoring
- **Features**: Clippy linting, k6 load testing, Prometheus metrics
- **Variables**: 45+ configurable settings

## Common Configuration Patterns

###  **Build Configuration**
All workflows support configurable:
- Language/framework versions
- Build tools and package managers  
- Test execution (unit, integration, E2E)
- Security scanning
- Docker image building

###  **Deployment Configuration**
All workflows support configurable:
- Environment detection (dev/staging/prod)
- Resource allocation per environment
- Replica counts and auto-scaling
- Health check endpoints
- Ingress and domain configuration

###  **Security & Secrets**
All workflows require:
- Harbor registry credentials
- Kubernetes configuration
- Environment-specific secrets
- Optional Artifactory integration

###  **Monitoring & Testing**
All workflows support configurable:
- Health check paths and intervals
- Performance/load testing
- Artifact collection
- Notification settings

## Quick Setup Guide

### 1. Choose Your Workflow
Select the appropriate workflow template for your application type.

### 2. Set Required Secrets
Configure these secrets in your GitHub repository:
```yaml
HARBOR_REGISTRY: "your-harbor-instance"
HARBOR_USERNAME: "your-username"  
HARBOR_PASSWORD: "your-password"
HARBOR_PROJECT: "your-project"
KUBECONFIG: "base64-encoded-config"
```

### 3. Configure Variables
Set GitHub repository variables for your environment:
```yaml
DOMAIN_SUFFIX: "your-domain.com"
APP_PORT: 8080
PROD_REPLICAS: 5
DEV_REPLICAS: 1
```

### 4. Copy and Customize
Copy the example workflow to `.github/workflows/` and adjust as needed.

## Variable Naming Conventions

###  **Environment Prefixes**
- `DEV_*` - Development environment settings
- `STAGING_*` - Staging environment settings  
- `PROD_*` - Production environment settings

###  **Application Settings**
- `APP_*` - Core application configuration
- `HEALTH_*` - Health check configuration
- `INGRESS_*` - Ingress and networking

###  **Infrastructure Settings**
- `HELM_*` - Helm deployment configuration
- `NAMESPACE_*` - Kubernetes namespace settings
- `RUNNER_*` - GitHub Actions runner configuration

###  **Testing Settings**
- `TEST_*` - General test configuration
- `LOAD_TEST_*` - Load testing specific
- `INTEGRATION_TEST_*` - Integration testing specific

## Best Practices

###  **DO**
- Use environment-specific variables for different resource requirements
- Set sensible defaults in workflow files
- Use GitHub environments for production deployments
- Enable security scanning and testing
- Configure monitoring and health checks

###  **DON'T** 
- Hardcode values directly in workflow files
- Store sensitive data in variables (use secrets)
- Use the same resource limits for all environments
- Skip health checks or monitoring configuration
- Forget to configure domain and ingress settings

## Support

For questions about configuration:
1. Check the specific workflow configuration file
2. Review the example configurations
3. Ensure all required secrets are set
4. Verify GitHub variables are properly configured