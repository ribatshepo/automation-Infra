# Python Project Template

A minimal, extensible Python project template with modern tooling and CI/CD integration.

## Features

- **Modern Package Management**: UV for fast dependency resolution and virtual environments
- **Code Quality**: Pre-commit hooks, linting, and formatting
- **Testing**: Pytest with coverage reporting
- **Documentation**: Automated documentation generation
- **CI/CD Integration**: GitHub Actions workflows from cicd-templates
- **Security**: Dependency scanning and security checks
- **Extensible**: Easy to customize for specific frameworks or applications

## Quick Start

### 1. Use This Template
```bash
# Create new repository from template
gh repo create my-python-project --template automation-infra/python-template
cd my-python-project
```

### 2. Initialize Project
```bash
# Run setup script
./scripts/setup.sh

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
uv sync
```

### 3. Configure CI/CD
```bash
# Set up GitHub Actions (optional)
./scripts/setup-cicd.sh
```

## Project Structure

```
python-template/
├── README.md                    # This file
├── pyproject.toml              # Project configuration and dependencies
├── uv.lock                     # Locked dependencies
├── .gitignore                  # Git ignore patterns
├── .pre-commit-config.yaml     # Pre-commit configuration
├── .github/                    # GitHub workflows
│   └── workflows/
│       └── ci.yml              # Basic CI workflow
├── scripts/                    # Setup and utility scripts
│   ├── setup.sh               # Project initialization
│   ├── setup-cicd.sh          # CI/CD setup
│   ├── test.sh                # Run tests
│   ├── lint.sh                # Run linting
│   ├── format.sh              # Format code
│   └── security-check.sh      # Security scanning
├── src/                        # Source code
│   └── project_name/           # Main package
│       ├── __init__.py
│       ├── main.py             # Entry point
│       └── core/               # Core modules
│           └── __init__.py
├── tests/                      # Test files
│   ├── __init__.py
│   ├── conftest.py             # Pytest configuration
│   └── test_main.py            # Example tests
├── docs/                       # Documentation
│   ├── index.md
│   └── api.md
└── examples/                   # Usage examples
    └── basic_usage.py
```

## Configuration

### Project Metadata (pyproject.toml)
```toml
[project]
name = "project-name"
version = "0.1.0"
description = "Project description"
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]
readme = "README.md"
license = {text = "MIT"}
requires-python = ">=3.9"
dependencies = [
    # Add your dependencies here
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "isort>=5.0.0",
    "flake8>=6.0.0",
    "mypy>=1.0.0",
    "pre-commit>=3.0.0",
]
docs = [
    "mkdocs>=1.4.0",
    "mkdocs-material>=9.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "--cov=src --cov-report=term-missing --cov-report=html"

[tool.black]
line-length = 88
target-version = ['py39']
include = '\.pyi?$'

[tool.isort]
profile = "black"
multi_line_output = 3
line_length = 88

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

## Development Workflow

### Setup Development Environment
```bash
# Install UV (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Initialize project
./scripts/setup.sh

# Install pre-commit hooks
pre-commit install
```

### Daily Development
```bash
# Run tests
./scripts/test.sh

# Run linting
./scripts/lint.sh

# Format code
./scripts/format.sh

# Security check
./scripts/security-check.sh

# Run all checks
./scripts/check-all.sh
```

### Adding Dependencies
```bash
# Add runtime dependency
uv add package-name

# Add development dependency
uv add --dev package-name

# Add optional dependency group
uv add --optional docs mkdocs
```

## CI/CD Integration

This template integrates with the automation-infra CI/CD templates:

### GitHub Actions Workflow
- Uses `cicd-templates/examples/main-python-deploy.yml`
- Automated testing and linting
- Security scanning
- Container building and deployment
- Documentation deployment

### Workflow Configuration
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: automation-infra/cicd-templates/.github/workflows/main-python-deploy.yml@main
    with:
      python_version: "3.9"
      project_name: "my-python-project"
      run_tests: true
      run_security_scan: true
      deploy_to_registry: false
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
```

## Customization

### Framework-Specific Extensions

#### FastAPI Extension
```bash
# Add FastAPI dependencies
uv add fastapi uvicorn

# Update main.py for FastAPI
# Add FastAPI-specific tests
# Update CI/CD for web service deployment
```

#### Django Extension
```bash
# Add Django dependencies
uv add django

# Initialize Django project
# Add Django-specific configuration
# Update CI/CD for Django deployment
```

#### Data Science Extension
```bash
# Add data science dependencies
uv add pandas numpy matplotlib jupyter

# Add notebook support
# Add data validation
# Update CI/CD for data pipeline deployment
```

### Custom Scripts
Add project-specific scripts to the `scripts/` directory:
- `scripts/migrate.sh` - Database migrations
- `scripts/seed.sh` - Data seeding
- `scripts/deploy.sh` - Custom deployment
- `scripts/benchmark.sh` - Performance testing

## Testing

### Test Structure
```python
# tests/test_main.py
import pytest
from src.project_name.main import main_function


def test_main_function():
    """Test the main function."""
    result = main_function()
    assert result is not None


class TestCoreModule:
    """Test core module functionality."""
    
    def test_core_feature(self):
        """Test core feature."""
        # Test implementation
        pass

    @pytest.mark.parametrize("input,expected", [
        ("test1", "result1"),
        ("test2", "result2"),
    ])
    def test_parametrized(self, input, expected):
        """Parametrized test example."""
        # Test implementation
        pass
```

### Test Configuration
```python
# tests/conftest.py
import pytest
from src.project_name import create_app


@pytest.fixture
def app():
    """Create application for testing."""
    app = create_app(testing=True)
    return app


@pytest.fixture
def client(app):
    """Create test client."""
    return app.test_client()
```

## Documentation

### MkDocs Configuration
```yaml
# mkdocs.yml
site_name: Project Name
site_description: Project description

nav:
  - Home: index.md
  - API Reference: api.md

theme:
  name: material
  palette:
    - scheme: default
      primary: blue
      accent: blue

plugins:
  - search
  - mkdocstrings:
      default_handler: python
      handlers:
        python:
          paths: [src]
```

### Auto-generated Documentation
```bash
# Generate API documentation
./scripts/generate-docs.sh

# Serve documentation locally
mkdocs serve

# Deploy documentation
mkdocs gh-deploy
```

## Security

### Dependency Scanning
- Automated vulnerability scanning with `safety`
- License compliance checking
- Security advisories monitoring

### Code Security
- Static analysis with `bandit`
- Secret detection with `detect-secrets`
- SAST integration in CI/CD

### Configuration
```yaml
# .pre-commit-config.yaml security hooks
repos:
  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
        args: ['-r', 'src/']

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

## Deployment Options

### Container Deployment
```dockerfile
# Dockerfile (auto-generated by setup script)
FROM python:3.9-slim

WORKDIR /app

# Install UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy source code
COPY src/ ./src/

# Run application
CMD ["uv", "run", "python", "-m", "src.project_name.main"]
```

### Serverless Deployment
- AWS Lambda integration
- Google Cloud Functions support
- Azure Functions compatibility

### Traditional Deployment
- SystemD service configuration
- WSGI/ASGI server setup
- Process management scripts

## Best Practices

### Code Quality
- Follow PEP 8 style guidelines
- Use type hints consistently
- Write comprehensive docstrings
- Maintain test coverage above 90%

### Project Organization
- Keep modules focused and cohesive
- Use clear naming conventions
- Separate configuration from code
- Document architectural decisions

### Dependency Management
- Pin dependency versions in production
- Regular dependency updates
- Security vulnerability monitoring
- License compliance checking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run all checks: `./scripts/check-all.sh`
5. Submit a pull request

## Support

- Documentation: [Project Docs](docs/)
- CI/CD Templates: [cicd-templates](../cicd-templates/)
- Issues: [GitHub Issues](https://github.com/your-org/project/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/project/discussions)