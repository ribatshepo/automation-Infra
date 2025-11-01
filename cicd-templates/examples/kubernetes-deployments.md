# Kubernetes Deployment Examples

This directory contains examples for deploying applications to Kubernetes using Harbor registry images.

## Available Deployment Methods

### 1. Raw Kubernetes Manifests
Use the `kubernetes-deploy.yml` workflow for generating and deploying standard Kubernetes manifests.

### 2. Helm Charts
Use the `helm-deploy.yml` workflow with the provided Helm chart template for more sophisticated deployments.

### 3. Full CI/CD Pipeline
Use the `full-pipeline.yml` workflow to build, push to Harbor, and deploy to Kubernetes in one workflow.

## Quick Start Examples

### Node.js Application Example

```yaml
# .github/workflows/deploy-nodejs.yml
name: 'Deploy Node.js App'

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    uses: ./.github/workflows/full-pipeline.yml
    with:
      dockerfile: './Dockerfile'
      context: '.'
      app-name: 'nodejs-api'
      environment: 'production'
      namespace: 'nodejs-apps'
      port: 3000
      replicas: 5
      enable-ingress: true
      ingress-host: 'api.example.com'
    secrets:
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

### Python FastAPI Example

```yaml
# .github/workflows/deploy-python.yml
name: 'Deploy Python FastAPI'

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: ./.github/workflows/full-pipeline.yml
    with:
      dockerfile: './docker/Dockerfile'
      context: '.'
      app-name: 'python-api'
      environment: 'staging'
      namespace: 'python-apps'
      port: 8000
      replicas: 3
      enable-ingress: true
      ingress-host: 'python-api-staging.example.com'
    secrets:
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

### Helm Deployment Example

```yaml
# .github/workflows/deploy-with-helm.yml
name: 'Deploy with Helm'

on:
  workflow_call:
    inputs:
      image-url:
        required: true
        type: string
      environment:
        required: false
        default: 'dev'
        type: string

jobs:
  build:
    uses: ./.github/workflows/docker.yml
    with:
      image-name: 'my-app'
      environment: ${{ inputs.environment }}
    secrets:
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}

  deploy:
    needs: build
    uses: ./.github/workflows/helm-deploy.yml
    with:
      chart-path: './helm-charts/app-template'
      release-name: 'my-app'
      namespace: 'default'
      environment: ${{ inputs.environment }}
      image-url: ${{ needs.build.outputs.image-url }}
      custom-values: |
        ingress:
          enabled: true
          hosts:
            - host: my-app.example.com
              paths:
                - path: /
                  pathType: Prefix
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
    secrets:
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
```

## Environment-Specific Deployments

### Development Environment

```yaml
jobs:
  deploy-dev:
    uses: ./.github/workflows/kubernetes-deploy.yml
    with:
      image-url: 'harbor.dev.example.com/development/my-app:latest'
      environment: 'dev'
      namespace: 'development'
      replicas: 1
      resource-requests-memory: '128Mi'
      resource-requests-cpu: '100m'
      resource-limits-memory: '256Mi'
      resource-limits-cpu: '200m'
    secrets:
      KUBECONFIG: ${{ secrets.DEV_KUBECONFIG }}
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
```

### Production Environment

```yaml
jobs:
  deploy-prod:
    uses: ./.github/workflows/kubernetes-deploy.yml
    with:
      image-url: 'harbor.prod.example.com/production/my-app:v1.2.3'
      environment: 'production'
      namespace: 'production'
      replicas: 5
      resource-requests-memory: '512Mi'
      resource-requests-cpu: '500m'
      resource-limits-memory: '1Gi'
      resource-limits-cpu: '1000m'
      enable-ingress: true
      ingress-host: 'api.example.com'
    secrets:
      KUBECONFIG: ${{ secrets.PROD_KUBECONFIG }}
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
```

## Configuration Examples

### Using ConfigMaps

```yaml
with:
  config-map: |
    {
      "DATABASE_URL": "postgres://user:pass@db:5432/myapp",
      "REDIS_URL": "redis://redis:6379",
      "LOG_LEVEL": "info"
    }
```

### Custom Resource Requirements

```yaml
with:
  resource-requests-memory: '1Gi'
  resource-requests-cpu: '500m'
  resource-limits-memory: '2Gi'
  resource-limits-cpu: '1000m'
```

### Health Check Configuration

```yaml
with:
  health-check-path: '/api/health'
```

## Required Secrets

Make sure to configure these secrets in your GitHub repository:

- `HARBOR_REGISTRY`: Harbor registry URL (e.g., `harbor.example.com`)
- `HARBOR_USERNAME`: Harbor username
- `HARBOR_PASSWORD`: Harbor password
- `HARBOR_PROJECT`: Harbor project name
- `KUBECONFIG`: Base64-encoded Kubernetes config file

## Best Practices

1. **Use environment-specific namespaces**: `development`, `staging`, `production`
2. **Tag images properly**: Use semantic versioning for production deployments
3. **Set appropriate resource limits**: Prevent resource starvation
4. **Enable monitoring**: Use Prometheus annotations for metrics collection
5. **Use ingress for external access**: Configure proper TLS certificates
6. **Implement health checks**: Ensure proper liveness and readiness probes
7. **Use Helm for complex applications**: Leverage templating for dynamic configurations

## Troubleshooting

### Common Issues

1. **Image pull errors**: Check Harbor credentials and image URL
2. **Pod startup failures**: Verify resource limits and health check endpoints
3. **Ingress not working**: Ensure ingress controller is installed and configured
4. **Deployment timeouts**: Increase timeout values or check resource availability

### Debugging Commands

```bash
# Check pod status
kubectl get pods -n <namespace>

# View pod logs
kubectl logs -f <pod-name> -n <namespace>

# Check deployment status
kubectl rollout status deployment/<app-name> -n <namespace>

# View Helm release status
helm status <release-name> -n <namespace>
```