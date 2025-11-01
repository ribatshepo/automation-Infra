# Getting Started with Universal CI/CD Templates

This guide will help you integrate the Universal CI/CD Templates into your project quickly and efficiently.

##  Quick Start

### 1. Clone or Download Templates

```bash
# Option 1: Clone the entire repository
git clone https://github.com/your-org/cicd-templates.git
cd cicd-templates

# Option 2: Download specific files
curl -O https://raw.githubusercontent.com/your-org/cicd-templates/main/setup.sh
chmod +x setup.sh
```

### 2. Run Setup Script

The setup script will automatically detect your project type and configure the appropriate workflows.

```bash
# Interactive setup (recommended for first-time users)
./setup.sh /path/to/your/project --interactive

# Automatic setup (based on project detection)
./setup.sh /path/to/your/project --automatic

# Setup in current directory
./setup.sh . --interactive
```

### 3. Configure GitHub Secrets

The setup script will generate a `github-secrets-template.md` file with all required secrets. Add these to your GitHub repository:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret from the template

### 4. Customize Configuration

Review and customize the generated files:
- `.github/workflows/ci-cd.yml` - Main workflow configuration
- `Dockerfile` - Container build configuration
- Workflow-specific files in `.github/workflows/`

### 5. Commit and Push

```bash
git add .github/ Dockerfile github-secrets-template.md
git commit -m "Add CI/CD pipeline with Harbor and JFrog integration"
git push
```

##  Technology-Specific Setup

### .NET Projects

**Requirements:**
- `.csproj` or `.sln` files
- `Dockerfile` (optional, will be generated)

**Workflow features:**
- NuGet package restoration and building
- Unit tests with coverage
- JFrog Xray security scanning
- NuGet package publishing to Artifactory
- Docker image building and pushing to Harbor

**Example configuration:**
```yaml
with:
  dotnet-version: '8.0.x'
  build-configuration: 'Release'
  target-framework: 'net8.0'
  run-tests: true
  security-scan: true
```

### Python Projects

**Requirements:**
- `requirements.txt`, `pyproject.toml`, or `setup.py`
- `Dockerfile` (optional, will be generated)

**Workflow features:**
- Dependency installation (pip, poetry, pipenv)
- Code formatting (Black, isort)
- Linting (flake8, mypy)
- Testing with coverage
- Security scanning (bandit, safety, JFrog Xray)
- PyPI package publishing to Artifactory
- Docker image building and pushing to Harbor

**Example configuration:**
```yaml
with:
  python-version: '3.11'
  package-manager: 'pip'
  run-linting: true
  run-security-scan: true
```

### Go Projects

**Requirements:**
- `go.mod` file
- `Dockerfile` (optional, will be generated)

**Workflow features:**
- Go module downloading and verification
- Linting with golangci-lint
- Testing with race detection and coverage
- Benchmarking
- Cross-platform binary building
- JFrog Xray security scanning
- Go module publishing to Artifactory
- Docker image building and pushing to Harbor

**Example configuration:**
```yaml
with:
  go-version: '1.21'
  run-benchmarks: true
  run-linting: true
```

### Rust Projects

**Requirements:**
- `Cargo.toml` file
- `Dockerfile` (optional, will be generated)

**Workflow features:**
- Cargo dependency management
- Code formatting (rustfmt)
- Linting (clippy)
- Testing with coverage (tarpaulin)
- Benchmarking
- Security auditing (cargo-audit)
- Cross-platform binary building
- Crate publishing to Artifactory
- Docker image building and pushing to Harbor

**Example configuration:**
```yaml
with:
  rust-version: 'stable'
  run-benchmarks: true
  run-linting: true
```

### Node.js Projects

**Requirements:**
- `package.json` file
- `Dockerfile` (optional, will be generated)

**Workflow features:**
- Dependency installation (npm, yarn, pnpm)
- Linting (ESLint)
- Code formatting (Prettier)
- Testing with coverage
- End-to-end testing (Playwright, Cypress)
- Security scanning (npm audit, JFrog Xray)
- Package publishing to Artifactory
- Docker image building and pushing to Harbor

**Example configuration:**
```yaml
with:
  node-version: '20'
  package-manager: 'npm'
  run-e2e-tests: true
```

### Docker-Only Projects

**Requirements:**
- `Dockerfile`

**Workflow features:**
- Multi-platform Docker building
- Security scanning with Trivy
- Image publishing to Harbor
- Kubernetes deployment manifests generation
- Docker Compose files generation

**Example configuration:**
```yaml
with:
  platforms: 'linux/amd64,linux/arm64'
  security-scan: true
  push-latest: true
```

##  Advanced Configuration

### Custom Build Arguments

Pass custom build arguments to Docker builds:

```yaml
with:
  build-args: |
    VERSION=${{ github.ref_name }}
    BUILD_DATE=${{ github.event.head_commit.timestamp }}
    GIT_COMMIT=${{ github.sha }}
```

### Environment-Specific Deployments

Configure different behaviors for different environments:

```yaml
jobs:
  staging-deploy:
    if: github.ref == 'refs/heads/develop'
    uses: ./.github/workflows/python.yml
    with:
      environment: 'staging'
      deploy-package: false
      security-scan: true

  production-deploy:
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/python.yml
    with:
      environment: 'production'
      deploy-package: true
      security-scan: true
```

### Conditional Workflows

Run different steps based on conditions:

```yaml
with:
  run-tests: ${{ github.event_name != 'release' }}
  deploy-package: ${{ github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/') }}
  security-scan: true
```

##  Security Best Practices

### Secret Management

- **Never commit secrets to your repository**
- Use GitHub repository secrets for sensitive data
- Rotate access tokens regularly
- Use principle of least privilege for service accounts

### Security Scanning

All workflows include comprehensive security scanning:

- **JFrog Xray**: Vulnerability scanning for packages and containers
- **Technology-specific tools**: 
  - npm audit (Node.js)
  - cargo audit (Rust)
  - bandit/safety (Python)
  - Trivy (Docker images)

### Access Control

Configure proper access control:

```yaml
# Example: Restrict production deployments
production-deploy:
  environment: production
  if: github.ref == 'refs/heads/main' && github.actor == 'authorized-user'
```

##  Monitoring and Observability

### Build Information

All packages include build metadata:
- Git commit SHA
- Build number
- Branch name
- Build timestamp
- Environment information

### Deployment Artifacts

Generated for each deployment:
- Docker Compose files
- Kubernetes manifests
- Deployment summaries
- Security scan reports

## 🆘 Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify GitHub secrets are correctly configured
   - Check Harbor and Artifactory credentials
   - Ensure service accounts have proper permissions

2. **Build Failures**
   - Review workflow logs in GitHub Actions
   - Check dependency issues
   - Verify build requirements

3. **Security Scan Failures**
   - Review vulnerability reports
   - Update dependencies
   - Configure security policies

### Debug Mode

Enable verbose logging:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### Getting Help

- Check the [troubleshooting guide](troubleshooting.md)
- Review [workflow examples](../examples/)
- Open an issue in the repository
- Contact the DevOps team

##  Updating Templates

To update to newer versions of the templates:

1. **Check for updates** in the main repository
2. **Run the setup script** again to update workflows
3. **Review changes** before committing
4. **Test** in a feature branch first

```bash
# Update templates
git pull origin main
./setup.sh . --automatic

# Review changes
git diff .github/

# Test and commit
git add .github/
git commit -m "Update CI/CD templates to latest version"
```

##  Additional Resources

- [Workflow Reference](workflows.md)
- [Custom Actions Guide](actions.md)
- [Configuration Reference](configuration.md)
- [Examples](../examples/)
- [JFrog Artifactory Documentation](https://www.jfrog.com/confluence/display/JFROG/JFrog+Artifactory)
- [Harbor Documentation](https://goharbor.io/docs/)

---

**Need help?** Open an issue or contact the DevOps team!