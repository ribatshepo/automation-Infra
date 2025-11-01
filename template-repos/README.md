# Template Repositories

This directory contains minimal, extensible project templates for various programming languages and technologies. Each template provides a complete development environment with modern tooling, testing, security, and CI/CD integration.

## Available Templates

### 1. Python Template (`python-template/`)
A modern Python project template with UV package management.

**Features:**
- UV for fast dependency management
- Pre-commit hooks with black, isort, flake8, mypy
- Pytest with coverage reporting
- Security scanning with bandit and safety
- CI/CD integration with automation-infra templates
- Docker and Kubernetes deployment ready

**Use Cases:**
- Web APIs (FastAPI, Django, Flask)
- Data science projects
- CLI applications
- Libraries and packages

### 2. Node.js Template (`nodejs-template/`)
A comprehensive Node.js/TypeScript template with multiple package manager support.

**Features:**
- TypeScript with strict configuration
- Support for npm, yarn, and pnpm
- ESLint and Prettier for code quality
- Jest testing framework
- Husky and lint-staged for git hooks
- Express.js foundation for web services
- Load testing with k6

**Use Cases:**
- REST APIs and web services
- Microservices architecture
- CLI tools
- Serverless functions

### 3. Go Template (`go-template/`)
A minimal Go template following standard project layout.

**Features:**
- Go modules with proper structure
- golangci-lint for comprehensive linting
- Comprehensive test coverage and benchmarking
- Security scanning with gosec and nancy
- Makefile for build automation
- Container-ready deployment

**Use Cases:**
- Web services and APIs
- CLI applications
- Microservices
- System tools and utilities

### 4. Rust Template (`rust-template/`)
A modern Rust project template with Cargo workspace support.

**Features:**
- Cargo workspace configuration
- Clippy for linting and code quality
- Comprehensive testing with cargo test
- Security auditing with cargo audit
- Cross-compilation support
- Performance benchmarking

**Use Cases:**
- System programming
- Web services with Actix/Warp
- CLI applications
- Performance-critical applications

### 5. .NET Template (`dotnet-template/`)
A comprehensive .NET template supporting multiple frameworks.

**Features:**
- Multi-target framework support
- NuGet package management
- xUnit testing framework
- Code analysis and formatting
- Entity Framework support
- Container and cloud deployment

**Use Cases:**
- Web APIs and services
- Desktop applications
- Cloud-native applications
- Enterprise applications

### 6. Docker Template (`docker-template/`)
A comprehensive Docker template for containerized applications.

**Features:**
- Multi-stage build optimization
- Security scanning and best practices
- Health checks and monitoring
- Multi-architecture builds
- Kubernetes deployment manifests
- CI/CD pipeline integration

**Use Cases:**
- Containerizing existing applications
- Microservices deployment
- Development environment standardization
- Production deployment pipelines

## Common Features

All templates include:

### Development Environment
- **Modern Tooling**: Latest versions of language-specific tools
- **Code Quality**: Linting, formatting, and static analysis
- **Testing**: Comprehensive testing frameworks and coverage
- **Security**: Dependency scanning and vulnerability checks
- **Documentation**: API documentation and deployment guides

### CI/CD Integration
- **GitHub Actions**: Pre-configured workflows
- **Automation Templates**: Integration with cicd-templates
- **Container Support**: Docker and Kubernetes deployments
- **Security Scanning**: Automated vulnerability detection
- **Performance Testing**: Load testing and benchmarking

### Deployment Options
- **Container Deployment**: Docker and Kubernetes ready
- **Serverless**: Cloud function deployment support
- **Traditional**: SystemD and process management
- **Cloud Native**: Helm charts and operators

### Project Structure
- **Standard Layout**: Industry-standard directory structures
- **Separation of Concerns**: Clear architectural boundaries
- **Extensibility**: Easy customization for specific needs
- **Documentation**: Comprehensive guides and examples

## Quick Start

### Using a Template

1. **Choose Your Template**
   ```bash
   # List available templates
   ls template-repos/
   ```

2. **Create New Project**
   ```bash
   # Copy template to new location
   cp -r template-repos/python-template my-new-project
   cd my-new-project
   ```

3. **Initialize Project**
   ```bash
   # Run setup script
   ./scripts/setup.sh
   ```

4. **Customize Configuration**
   ```bash
   # Update project metadata
   # - Update package.json, pyproject.toml, go.mod, etc.
   # - Configure CI/CD workflows
   # - Set up repository secrets
   ```

5. **Start Development**
   ```bash
   # Run development server or tests
   # Follow template-specific README
   ```

### Template Selection Guide

| Use Case | Recommended Template | Rationale |
|----------|---------------------|-----------|
| Web API Development | Node.js, Go, .NET | Fast development, good performance |
| Data Science/ML | Python | Rich ecosystem, libraries |
| System Programming | Go, Rust | Performance, memory safety |
| Enterprise Applications | .NET, Java | Mature ecosystem, enterprise features |
| CLI Tools | Go, Rust, Python | Single binary, cross-platform |
| Microservices | Go, Node.js, .NET | Lightweight, container-friendly |
| High Performance | Rust, Go | Memory efficiency, speed |
| Containerization | Docker Template | Best practices, security |

## Customization

### Framework-Specific Extensions

Each template can be extended for specific frameworks:

**Python:**
- FastAPI for web APIs
- Django for full-stack applications
- Pandas/NumPy for data science
- Click for CLI applications

**Node.js:**
- Express.js for web services
- NestJS for enterprise applications
- Next.js for full-stack React
- Electron for desktop apps

**Go:**
- Gin for web services
- Cobra for CLI applications
- gRPC for microservices
- Kubernetes operators

**Rust:**
- Actix-web for web services
- Clap for CLI applications
- Tokio for async applications
- WebAssembly for web

**.NET:**
- ASP.NET Core for web APIs
- Entity Framework for data access
- Blazor for web applications
- MAUI for cross-platform

### Adding Custom Tools

Templates can be extended with additional tools:

```bash
# Add monitoring
# - Prometheus metrics
# - Grafana dashboards
# - APM integration

# Add databases
# - PostgreSQL/MySQL setup
# - Redis caching
# - Database migrations

# Add messaging
# - RabbitMQ/Kafka setup
# - Event sourcing
# - Message queues
```

## Best Practices

### Template Usage
1. **Always run setup scripts** after copying templates
2. **Update project metadata** (names, versions, URLs)
3. **Configure repository secrets** for CI/CD
4. **Review security settings** before deployment
5. **Customize for your specific needs**

### Development Workflow
1. **Use provided scripts** for consistent operations
2. **Run all checks** before committing code
3. **Follow testing guidelines** for quality assurance
4. **Document architectural decisions**
5. **Keep dependencies updated**

### Deployment Strategy
1. **Test in staging** before production deployment
2. **Use infrastructure as code** for consistency
3. **Monitor application performance**
4. **Implement proper logging**
5. **Plan for disaster recovery**

## Contributing

### Adding New Templates

1. **Create Template Directory**
   ```bash
   mkdir template-repos/new-language-template
   ```

2. **Follow Template Structure**
   - README.md with comprehensive documentation
   - Setup scripts in `scripts/` directory
   - CI/CD integration with automation templates
   - Docker and Kubernetes configurations
   - Testing and security tools

3. **Include Required Components**
   - Project structure and configuration files
   - Development environment setup
   - Testing framework and examples
   - Security scanning tools
   - Documentation and examples

4. **Test Template**
   - Verify setup script works correctly
   - Test CI/CD pipeline integration
   - Validate security scanning
   - Check deployment configurations

### Improving Existing Templates

1. **Update Dependencies** to latest stable versions
2. **Add New Tools** that improve developer experience
3. **Enhance Security** with better scanning and practices
4. **Improve Documentation** with examples and guides
5. **Optimize Performance** of build and deployment processes

## Support

- **Documentation**: Each template includes comprehensive documentation
- **CI/CD Integration**: All templates work with automation-infra CI/CD templates
- **Issues**: Report issues in the main repository
- **Discussions**: Join discussions for best practices and improvements

## License

All templates are provided under the same license as the main automation-infra project.