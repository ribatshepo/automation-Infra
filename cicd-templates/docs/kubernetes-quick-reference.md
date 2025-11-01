# Kubernetes Deployment Quick Reference

## Overview

This document provides a quick reference for deploying applications to Kubernetes using the CI/CD templates with Harbor registry integration.

## Workflow Files

| Workflow | Purpose | Use Case |
|----------|---------|----------|
| `kubernetes-deploy.yml` | Raw K8s manifests | Simple deployments, manual control |
| `helm-deploy.yml` | Helm chart deployment | Complex apps, templating needed |
| `full-pipeline.yml` | Complete CI/CD | Build → Harbor → Kubernetes |

## Quick Start Commands

### 1. Setup Repository Secrets

```bash
# Using GitHub CLI
gh secret set KUBECONFIG --body "$(cat ~/.kube/config | base64 -w 0)"
gh secret set HARBOR_REGISTRY --body "harbor.example.com"
gh secret set HARBOR_USERNAME --body "your-username"
gh secret set HARBOR_PASSWORD --body "your-password"
gh secret set HARBOR_PROJECT --body "your-project"
```

### 2. Create Basic Deployment Workflow

```yaml
# .github/workflows/deploy.yml
name: 'Deploy App'
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: ./.github/workflows/full-pipeline.yml
    with:
      app-name: 'my-app'
      environment: 'production'
      namespace: 'apps'
      replicas: 3
      enable-ingress: true
      ingress-host: 'my-app.example.com'
    secrets:
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

## Common Configurations

### Development Environment

```yaml
with:
  environment: 'dev'
  namespace: 'development'
  replicas: 1
  resource-requests-memory: '128Mi'
  resource-requests-cpu: '100m'
  resource-limits-memory: '256Mi'
  resource-limits-cpu: '200m'
```

### Staging Environment

```yaml
with:
  environment: 'staging'
  namespace: 'staging'
  replicas: 2
  resource-requests-memory: '256Mi'
  resource-requests-cpu: '250m'
  resource-limits-memory: '512Mi'
  resource-limits-cpu: '500m'
  enable-ingress: true
  ingress-host: 'staging-app.example.com'
```

### Production Environment

```yaml
with:
  environment: 'production'
  namespace: 'production'
  replicas: 5
  resource-requests-memory: '512Mi'
  resource-requests-cpu: '500m'
  resource-limits-memory: '1Gi'
  resource-limits-cpu: '1000m'
  enable-ingress: true
  ingress-host: 'app.example.com'
```

## Helm Chart Customization

### Custom Values Example

```yaml
# In workflow
with:
  custom-values: |
    # Application settings
    app:
      port: 3000
      healthCheckPath: '/api/health'
    
    # Resource configuration
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
    
    # Ingress configuration
    ingress:
      enabled: true
      className: "nginx"
      annotations:
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
        nginx.ingress.kubernetes.io/rate-limit: "100"
      hosts:
        - host: api.example.com
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: api-tls
          hosts:
            - api.example.com
    
    # Autoscaling
    autoscaling:
      enabled: true
      minReplicas: 3
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70
    
    # Environment variables
    env:
      NODE_ENV: production
      DATABASE_URL: postgres://user:pass@db:5432/app
      REDIS_URL: redis://redis:6379
    
    # ConfigMap
    configMap:
      enabled: true
      data:
        LOG_LEVEL: info
        FEATURE_FLAGS: '{"newUI": true, "analytics": true}'
```

### Using External Values File

```yaml
# In workflow
with:
  values-file: './k8s/production-values.yaml'
```

```yaml
# k8s/production-values.yaml
app:
  name: 'my-production-app'
  port: 8080

image:
  tag: 'v1.2.3'

deployment:
  replicas: 5

resources:
  requests:
    memory: '1Gi'
    cpu: '500m'
  limits:
    memory: '2Gi'
    cpu: '1000m'

ingress:
  enabled: true
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix

monitoring:
  enabled: true
```

## Environment-Specific Deployments

### Multi-Environment Pipeline

```yaml
name: 'Multi-Environment Deploy'
on:
  push:
    branches: [main, develop]

jobs:
  # Development deployment
  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    uses: ./.github/workflows/full-pipeline.yml
    with:
      environment: 'dev'
      namespace: 'development'
      replicas: 1
      ingress-host: 'dev-app.example.com'
    secrets:
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
      KUBECONFIG: ${{ secrets.DEV_KUBECONFIG }}

  # Production deployment
  deploy-prod:
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/full-pipeline.yml
    with:
      environment: 'production'
      namespace: 'production'
      replicas: 5
      enable-ingress: true
      ingress-host: 'app.example.com'
    secrets:
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
      KUBECONFIG: ${{ secrets.PROD_KUBECONFIG }}
```

## Troubleshooting

### Common Issues

1. **KUBECONFIG Secret**
   ```bash
   # Encode kubeconfig properly
   cat ~/.kube/config | base64 -w 0
   ```

2. **Harbor Authentication**
   ```bash
   # Test Harbor login
   docker login harbor.example.com -u username -p password
   ```

3. **Namespace Issues**
   ```bash
   # Create namespace manually
   kubectl create namespace my-namespace
   ```

4. **Ingress Not Working**
   ```bash
   # Check ingress controller
   kubectl get pods -n ingress-nginx
   
   # Check ingress resource
   kubectl get ingress -n my-namespace
   kubectl describe ingress my-app-ingress -n my-namespace
   ```

### Debug Commands

```bash
# Check deployment status
kubectl get deployments -n my-namespace

# View pod logs
kubectl logs -f deployment/my-app -n my-namespace

# Check pod events
kubectl get events -n my-namespace --sort-by='.lastTimestamp'

# Describe pod for troubleshooting
kubectl describe pod <pod-name> -n my-namespace

# Check Helm release
helm list -n my-namespace
helm status my-release -n my-namespace
```

## Best Practices

1. **Use namespace per environment**: `dev`, `staging`, `prod`
2. **Set resource limits**: Prevent resource starvation
3. **Configure health checks**: Ensure reliable deployments
4. **Use semantic versioning**: Tag images properly
5. **Enable monitoring**: Add Prometheus annotations
6. **Secure ingress**: Use TLS certificates
7. **Test deployments**: Use dry-run before production
8. **Monitor resources**: Set up alerts for resource usage

## Security Considerations

1. **Image scanning**: Enable security scanning in workflows
2. **Pod security**: Use security contexts
3. **Network policies**: Restrict pod-to-pod communication
4. **Secrets management**: Use Kubernetes secrets for sensitive data
5. **RBAC**: Implement proper role-based access control
6. **TLS termination**: Ensure secure communication

## Resource Planning

### Small Applications
- **CPU**: 100m-250m
- **Memory**: 128Mi-256Mi
- **Replicas**: 1-2

### Medium Applications
- **CPU**: 250m-500m
- **Memory**: 256Mi-512Mi
- **Replicas**: 2-3

### Large Applications
- **CPU**: 500m-1000m
- **Memory**: 512Mi-1Gi
- **Replicas**: 3-5+