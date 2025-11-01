# Universal CI/CD Templates

A comprehensive, modular CI/CD template repository supporting multiple technologies with automated deployments to Harbor (Docker images), JFrog Artifactory (packages), and Kubernetes orchestration.

## Features

- **Multi-Technology Support**: .NET, Python, Go, Rust, Node.js, Docker
- **Dual Registry Integration**: Harbor for containers, JFrog Artifactory for packages
- **Kubernetes Deployment**: Native Kubernetes and Helm chart deployments
- **Modular Design**: Reusable components and actions
- **Security-First**: Built-in security scanning and vulnerability checks
- **Flexible Deployment**: Support for staging, production, and custom environments
- **Comprehensive Testing**: Unit tests, integration tests, and quality gates
- **Full CI/CD Pipeline**: From source code to running containers in Kubernetes

## Repository Structure

```
cicd-templates/
├── .github/
│   ├── workflows/              # Main CI/CD workflows
│   │   ├── dotnet.yml          # .NET build and deploy
│   │   ├── python.yml          # Python build and deploy
│   │   ├── golang.yml          # Go build and deploy
│   │   ├── rust.yml            # Rust build and deploy
│   │   ├── nodejs.yml          # Node.js build and deploy
│   │   ├── docker.yml          # Docker build and push
│   │   ├── kubernetes-deploy.yml # Kubernetes deployment
│   │   ├── helm-deploy.yml     # Helm deployment
│   │   └── full-pipeline.yml   # Complete CI/CD pipeline
│   └── actions/                # Custom composite actions
│       ├── harbor-push/        # Harbor container push action
│       ├── artifactory-push/   # Artifactory package push action
│       ├── security-scan/      # Security scanning action
│       └── quality-gate/       # Quality gate checks
├── helm-charts/                # Helm chart templates
│   └── app-template/           # Generic application Helm chart
├── scripts/                    # Utility scripts
├── templates/                  # Configuration templates
├── docs/                      # Documentation
└── examples/                  # Example implementations
    ├── dotnet-webapi.md       # .NET Web API example
    └── kubernetes-deployments.md # Kubernetes deployment examples
```

## Supported Technologies & Deployments

| Technology | Package Registry | Container Registry | Kubernetes | Workflow |
|------------|------------------|-------------------|------------|----------|
| .NET | JFrog Artifactory (NuGet) | Harbor | ✅ | `dotnet.yml` |
| Python | JFrog Artifactory (PyPI) | Harbor | ✅ | `python.yml` |
| Go | JFrog Artifactory (Go) | Harbor | ✅ | `golang.yml` |
| Rust | JFrog Artifactory (Cargo) | Harbor | ✅ | `rust.yml` |
| Node.js | JFrog Artifactory (npm) | Harbor | ✅ | `nodejs.yml` |
| Docker | - | Harbor | ✅ | `docker.yml` |
| Kubernetes | - | - | ✅ | `kubernetes-deploy.yml` |
| Helm | - | - | ✅ | `helm-deploy.yml` |

## Quick Start

### 1. Repository Setup

1. **Copy workflow files** to your repository:
   ```bash
   cp .github/workflows/[technology].yml your-repo/.github/workflows/
   cp -r .github/actions/ your-repo/.github/
   ```

2. **Configure repository secrets**:
   ```bash
   # Harbor Configuration
   HARBOR_REGISTRY=your-harbor-instance.com
   HARBOR_USERNAME=your-harbor-user
   HARBOR_PASSWORD=your-harbor-password
   
   # JFrog Artifactory Configuration
   ARTIFACTORY_URL=https://your-artifactory-instance.com
   ARTIFACTORY_USERNAME=your-artifactory-user
   ARTIFACTORY_PASSWORD=your-artifactory-password
   ARTIFACTORY_ACCESS_TOKEN=your-access-token
   
   # Optional: Custom configuration
   DOCKER_REGISTRY_PREFIX=your-organization
   PACKAGE_NAMESPACE=your-namespace
   ```

### 2. Technology-Specific Setup

#### .NET Projects
```yaml
# Add to your repository: .github/workflows/dotnet.yml
name: .NET CI/CD
on: [push, pull_request]
jobs:
  build-and-deploy:
    uses: ./.github/workflows/dotnet.yml
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      ARTIFACTORY_USERNAME: ${{ secrets.ARTIFACTORY_USERNAME }}
      ARTIFACTORY_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }}
```

#### Python Projects
```yaml
# Add to your repository: .github/workflows/python.yml
name: Python CI/CD
on: [push, pull_request]
jobs:
  build-and-deploy:
    uses: ./.github/workflows/python.yml
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      ARTIFACTORY_USERNAME: ${{ secrets.ARTIFACTORY_USERNAME }}
      ARTIFACTORY_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }}
```

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `HARBOR_REGISTRY` | Harbor registry URL | Yes | - |
| `HARBOR_USERNAME` | Harbor username | Yes | - |
| `HARBOR_PASSWORD` | Harbor password | Yes | - |
| `ARTIFACTORY_URL` | JFrog Artifactory URL | Yes | - |
| `ARTIFACTORY_USERNAME` | Artifactory username | Yes | - |
| `ARTIFACTORY_PASSWORD` | Artifactory password | Yes | - |
| `DOCKER_REGISTRY_PREFIX` | Docker image prefix | No | `library` |
| `PACKAGE_NAMESPACE` | Package namespace | No | `default` |

### Workflow Customization

Each workflow supports customization through inputs:

```yaml
with:
  build-config: 'Release'
  target-framework: 'net8.0'
  run-tests: true
  security-scan: true
  deploy-environment: 'staging'
```

## Kubernetes Deployments

The CI/CD templates now include comprehensive Kubernetes deployment capabilities with three different approaches:

### 1. Raw Kubernetes Manifests (`kubernetes-deploy.yml`)

Deploy applications using generated Kubernetes manifests:

```yaml
name: 'Deploy to Kubernetes'
on: [push]
jobs:
  deploy:
    uses: ./.github/workflows/kubernetes-deploy.yml
    with:
      image-url: 'harbor.example.com/project/app:latest'
      environment: 'production'
      namespace: 'my-app'
      replicas: 3
      port: 8080
      enable-ingress: true
      ingress-host: 'app.example.com'
      deploy-to-cluster: true
    secrets:
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
```

### 2. Helm Chart Deployments (`helm-deploy.yml`)

Deploy using the provided Helm chart template or custom charts:

```yaml
name: 'Deploy with Helm'
on: [push]
jobs:
  deploy:
    uses: ./.github/workflows/helm-deploy.yml
    with:
      chart-path: './helm-charts/app-template'
      release-name: 'my-app-prod'
      namespace: 'production'
      environment: 'production'
      image-url: 'harbor.example.com/project/app:v1.2.3'
      custom-values: |
        ingress:
          enabled: true
          hosts:
            - host: app.example.com
              paths:
                - path: /
                  pathType: Prefix
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
    secrets:
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
```

### 3. Full CI/CD Pipeline (`full-pipeline.yml`)

Complete pipeline from source code to Kubernetes deployment:

```yaml
name: 'Full CI/CD Pipeline'
on: [push]
jobs:
  deploy:
    uses: ./.github/workflows/full-pipeline.yml
    with:
      dockerfile: './Dockerfile'
      context: '.'
      app-name: 'my-application'
      environment: 'production'
      namespace: 'apps'
      port: 8080
      replicas: 5
      enable-ingress: true
      ingress-host: 'my-app.example.com'
      deploy-to-k8s: true
      security-scan: true
    secrets:
      HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

### Kubernetes Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image-url` | Harbor image URL | Required |
| `environment` | Deployment environment | `dev` |
| `namespace` | Kubernetes namespace | `default` |
| `replicas` | Number of replicas | `3` |
| `port` | Application port | `8080` |
| `enable-ingress` | Enable ingress | `false` |
| `ingress-host` | Ingress hostname | Auto-generated |
| `resource-requests-memory` | Memory requests | `256Mi` |
| `resource-requests-cpu` | CPU requests | `250m` |
| `resource-limits-memory` | Memory limits | `512Mi` |
| `resource-limits-cpu` | CPU limits | `500m` |

### Required Kubernetes Secrets

```bash
# Kubernetes configuration (base64 encoded)
KUBECONFIG=<base64-encoded-kubeconfig>

# Harbor registry credentials
HARBOR_REGISTRY=harbor.example.com
HARBOR_USERNAME=username
HARBOR_PASSWORD=password
HARBOR_PROJECT=project-name
```

### Helm Chart Features

The included Helm chart template provides:

- **Auto-scaling**: HorizontalPodAutoscaler with CPU/Memory metrics
- **Health Checks**: Configurable liveness, readiness, and startup probes
- **Security**: Pod security contexts and network policies
- **Monitoring**: Prometheus annotations for metrics collection
- **Storage**: Optional persistent volume claims
- **Ingress**: Nginx ingress with TLS support
- **Config Management**: ConfigMaps and Secrets integration

## Integration Examples

### Example 1: .NET Web API
```bash
# Project structure
my-dotnet-api/
├── src/
│   └── MyApi/
├── tests/
├── Dockerfile
├── .github/
│   └── workflows/
│       └── ci-cd.yml
└── README.md
```

### Example 2: Python Package
```bash
# Project structure
my-python-package/
├── src/
├── tests/
├── setup.py
├── requirements.txt
├── Dockerfile
├── .github/
│   └── workflows/
│       └── ci-cd.yml
└── README.md
```

## Security Features

- **Dependency Scanning**: Automated vulnerability scanning
- **Container Scanning**: Harbor integration for container security
- **Secret Detection**: Prevent secrets from being committed
- **Code Quality**: SonarQube/CodeQL integration
- **License Compliance**: Automated license checking

## Documentation

- [Getting Started Guide](docs/getting-started.md)
- [Workflow Reference](docs/workflows.md)
- [Custom Actions Guide](docs/actions.md)
- [Configuration Reference](docs/configuration.md)
- [Troubleshooting](docs/troubleshooting.md)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- [GitHub Issues](../../issues)
- [Documentation](docs/)
- [Examples](examples/)

---

