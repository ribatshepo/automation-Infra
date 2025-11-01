# Main Workflow Examples

This directory contains complete examples of main workflows that use the reusable CI/CD workflows. These examples demonstrate how to orchestrate complex deployment pipelines for different technologies.

## Available Examples

### 1. **main-dotnet-deploy.yml** - .NET Web API Deployment
- **Technology**: .NET 8.0 Web API
- **Features**:
  - Build and test with the `dotnet.yml` workflow
  - Deploy to Kubernetes using Helm with `helm-deploy.yml`
  - Environment-specific configurations (dev/staging/prod)
  - Health checks and monitoring
  - Database connection strings
  - Manual workflow dispatch with environment selection

### 2. **main-nodejs-deploy.yml** - Node.js Application Deployment
- **Technology**: Node.js/Express application
- **Features**:
  - Build and test with the `nodejs.yml` workflow
  - Full pipeline deployment using `full-pipeline.yml`
  - Performance testing for production deployments
  - Environment-specific resource allocation
  - Ingress configuration

### 3. **main-python-deploy.yml** - Python FastAPI Deployment
- **Technology**: Python FastAPI microservice
- **Features**:
  - Build and test with the `python.yml` workflow
  - Direct Kubernetes deployment using `kubernetes-deploy.yml`
  - Database migration jobs for production
  - ConfigMap integration for environment variables
  - Custom health check endpoints

### 4. **main-go-deploy.yml** - Go Microservice Deployment
- **Technology**: Go web service
- **Features**:
  - Build and test with the `golang.yml` workflow
  - Helm deployment with extensive customization
  - Integration testing against deployed services
  - Advanced autoscaling configuration
  - Feature flags and configuration management

### 5. **main-rust-deploy.yml** - Rust Web Service Deployment
- **Technology**: Rust web service
- **Features**:
  - Build and test with the `rust.yml` workflow
  - Separate staging and production deployments
  - Load testing with k6 for production
  - Advanced Helm configurations with TLS
  - Cross-compilation support

### 6. **main-docker-deploy.yml** - Generic Docker Application
- **Technology**: Any containerized application
- **Features**:
  - Multi-platform Docker builds with `docker.yml`
  - Environment-specific deployment strategies
  - Development with simple manifests, production with Helm
  - Smoke testing after deployment
  - Multi-architecture support (AMD64/ARM64)

## Common Patterns

### Environment-Based Deployment
All examples follow this pattern:
- **Develop branch** → Development environment
- **Main branch** → Production environment
- **Manual dispatch** → Choose any environment

### Security and Best Practices
- All workflows include security scanning
- Production deployments require manual approval
- Secrets are properly managed
- Resource limits are environment-specific

### Testing Strategy
- Unit and integration tests run before deployment
- Smoke tests verify deployment health
- Performance/load tests for critical services
- Environment-specific test configurations

## How to Use These Examples

### 1. Copy to Your Repository
```bash
# Copy the workflow you need to your .github/workflows/ directory
cp examples/main-nodejs-deploy.yml .github/workflows/deploy.yml
```

### 2. Configure Required Secrets
Set these secrets in your GitHub repository:

```bash
# Harbor Registry
HARBOR_REGISTRY=harbor.example.com
HARBOR_USERNAME=your-username
HARBOR_PASSWORD=your-password
HARBOR_PROJECT=your-project

# JFrog Artifactory (if using)
ARTIFACTORY_URL=https://your-org.jfrog.io
ARTIFACTORY_USERNAME=your-username
ARTIFACTORY_PASSWORD=your-password

# Kubernetes
KUBECONFIG=<base64-encoded-kubeconfig>
DEV_KUBECONFIG=<base64-encoded-dev-kubeconfig>
STAGING_KUBECONFIG=<base64-encoded-staging-kubeconfig>

# Application-specific
DATABASE_URL=postgresql://...
DATABASE_CONNECTION_STRING=Server=...
REDIS_URL=redis://...
```

### 3. Customize for Your Application
Edit the workflow to match your application:

```yaml
# Update application name
app-name: 'your-app-name'

# Update ports
port: 3000  # Your application port

# Update health check endpoints
health-check-path: '/api/health'

# Update resource requirements
resource-requests-memory: '512Mi'
resource-limits-memory: '1Gi'

# Update ingress hostnames
ingress-host: 'your-app.example.com'
```

### 4. Create Environment-Specific Values (For Helm)
Create Helm values files:

```yaml
# helm/values-dev.yaml
resources:
  requests:
    memory: '128Mi'
    cpu: '100m'

# helm/values-staging.yaml
resources:
  requests:
    memory: '256Mi'
    cpu: '250m'

# helm/values-prod.yaml
resources:
  requests:
    memory: '512Mi'
    cpu: '500m'
```

## Workflow Triggers

### Automatic Triggers
- **Push to main/develop**: Automatic deployment to respective environments
- **Pull request**: Dry-run deployment for validation

### Manual Triggers
- **workflow_dispatch**: Manual deployment with environment selection
- **Environment-specific secrets**: Different configurations per environment

## Advanced Features

### Multi-Environment Deployments
```yaml
jobs:
  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    # Deploy to development
  
  deploy-staging:
    if: github.event.inputs.environment == 'staging'
    # Deploy to staging
  
  deploy-prod:
    if: github.ref == 'refs/heads/main'
    # Deploy to production
```

### Conditional Steps
```yaml
# Run performance tests only for production
performance-test:
  if: github.ref == 'refs/heads/main' && github.event.inputs.environment == 'prod'
  # Performance testing steps

# Database migrations only for production
database-migration:
  if: github.ref == 'refs/heads/main'
  environment: production  # Requires manual approval
  # Migration steps
```

### Artifact Management
```yaml
# Upload deployment manifests
- name: 'Upload artifacts'
  uses: actions/upload-artifact@v4
  with:
    name: kubernetes-manifests-${{ env.ENVIRONMENT }}
    path: |
      k8s-manifests.yaml
      helm-values.yaml
    retention-days: 30
```

## Troubleshooting

### Common Issues

1. **Workflow not found**: Ensure the reusable workflow exists in `.github/workflows/`
2. **Secret access**: Verify all required secrets are configured
3. **Kubernetes access**: Check KUBECONFIG is valid and base64-encoded
4. **Harbor authentication**: Verify Harbor credentials and project permissions
5. **Resource limits**: Ensure cluster has sufficient resources

### Debugging Tips

1. **Check workflow logs**: Review the detailed logs in GitHub Actions
2. **Validate manually**: Test commands locally before adding to workflows
3. **Use dry-run**: Enable dry-run for testing without actual deployment
4. **Start simple**: Begin with basic deployment and add complexity gradually

### Support Commands

```bash
# Test Harbor connection
docker login harbor.example.com -u username -p password

# Test Kubernetes connection
kubectl cluster-info
kubectl get nodes

# Validate Helm chart
helm lint ./helm-charts/app-template
helm template test ./helm-charts/app-template --dry-run

# Test application health
curl -f https://your-app.example.com/health
```

## Best Practices

1. **Start small**: Begin with the simplest workflow that meets your needs
2. **Environment parity**: Keep environments as similar as possible
3. **Security first**: Always enable security scanning and use least privilege
4. **Monitor everything**: Include health checks and monitoring in all deployments
5. **Test thoroughly**: Include comprehensive testing at all levels
6. **Document changes**: Update workflows as your application evolves

---

These examples provide a solid foundation for implementing robust CI/CD pipelines. Choose the one that best matches your technology stack and customize it for your specific requirements.