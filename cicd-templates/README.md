# Universal CI/CD Templates

A comprehensive, modular CI/CD template repository supporting multiple technologies with automated deployments to Harbor (Docker images) and JFrog Artifactory (packages).

## Features

- **Multi-Technology Support**: .NET, Python, Go, Rust, Node.js, Docker
- **Dual Registry Integration**: Harbor for containers, JFrog Artifactory for packages
- **Modular Design**: Reusable components and actions
- **Security-First**: Built-in security scanning and vulnerability checks
- **Flexible Deployment**: Support for staging, production, and custom environments
- **Comprehensive Testing**: Unit tests, integration tests, and quality gates

## Repository Structure

```
cicd-templates/
├── .github/
│   ├── workflows/          # Main CI/CD workflows
│   │   ├── dotnet.yml      # .NET build and deploy
│   │   ├── python.yml      # Python build and deploy
│   │   ├── golang.yml      # Go build and deploy
│   │   ├── rust.yml        # Rust build and deploy
│   │   ├── nodejs.yml      # Node.js build and deploy
│   │   ├── docker.yml      # Docker build and push
│   │   └── reusable/       # Reusable workflow templates
│   └── actions/            # Custom composite actions
│       ├── harbor-push/    # Harbor container push action
│       ├── artifactory-push/ # Artifactory package push action
│       ├── security-scan/  # Security scanning action
│       └── quality-gate/   # Quality gate checks
├── scripts/                # Utility scripts
├── templates/              # Configuration templates
├── docs/                   # Documentation
└── examples/               # Example implementations
```

## Supported Technologies

| Technology | Package Registry | Container Registry | Workflow |
|------------|------------------|-------------------|----------|
| .NET | JFrog Artifactory (NuGet) | Harbor | `dotnet.yml` |
| Python | JFrog Artifactory (PyPI) | Harbor | `python.yml` |
| Go | JFrog Artifactory (Go) | Harbor | `golang.yml` |
| Rust | JFrog Artifactory (Cargo) | Harbor | `rust.yml` |
| Node.js | JFrog Artifactory (npm) | Harbor | `nodejs.yml` |
| Docker | - | Harbor | `docker.yml` |

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

