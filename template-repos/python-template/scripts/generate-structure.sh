#!/bin/bash
set -e

echo "Generating basic project structure..."

# Create main package
cat > src/project_name/__init__.py << 'EOF'
"""Project Name - A minimal Python project."""

__version__ = "0.1.0"
__author__ = "Your Name"
__email__ = "your.email@example.com"

from .main import main

__all__ = ["main"]
EOF

# Create main module
cat > src/project_name/main.py << 'EOF'
"""Main module for the project."""

import sys
from typing import Optional


def main(args: Optional[list[str]] = None) -> int:
    """Main entry point for the application.
    
    Args:
        args: Command line arguments. If None, uses sys.argv[1:]
        
    Returns:
        Exit code (0 for success, non-zero for error)
    """
    if args is None:
        args = sys.argv[1:]
    
    print("Hello from Python project template!")
    print(f"Arguments: {args}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
EOF

# Create core module
cat > src/project_name/core/__init__.py << 'EOF'
"""Core modules for the project."""
EOF

cat > src/project_name/core/utils.py << 'EOF'
"""Utility functions."""

from typing import Any, Dict


def get_version() -> str:
    """Get the current version of the project.
    
    Returns:
        Version string
    """
    from .. import __version__
    return __version__


def validate_config(config: Dict[str, Any]) -> bool:
    """Validate configuration dictionary.
    
    Args:
        config: Configuration dictionary to validate
        
    Returns:
        True if configuration is valid, False otherwise
    """
    required_keys = ["name", "version"]
    return all(key in config for key in required_keys)
EOF

# Create test files
cat > tests/__init__.py << 'EOF'
"""Test package."""
EOF

cat > tests/conftest.py << 'EOF'
"""Pytest configuration and fixtures."""

import pytest
from typing import Dict, Any


@pytest.fixture
def sample_config() -> Dict[str, Any]:
    """Sample configuration for testing."""
    return {
        "name": "test-project",
        "version": "0.1.0",
        "debug": False,
    }


@pytest.fixture
def sample_args() -> list[str]:
    """Sample command line arguments for testing."""
    return ["--verbose", "--config", "test.yaml"]
EOF

cat > tests/test_main.py << 'EOF'
"""Tests for main module."""

import pytest
from src.project_name.main import main


def test_main_no_args():
    """Test main function with no arguments."""
    result = main([])
    assert result == 0


def test_main_with_args(sample_args):
    """Test main function with arguments."""
    result = main(sample_args)
    assert result == 0


class TestMainFunction:
    """Test class for main function."""
    
    def test_main_returns_zero(self):
        """Test that main returns zero on success."""
        result = main(["test"])
        assert result == 0
    
    @pytest.mark.parametrize("args,expected", [
        ([], 0),
        (["arg1"], 0),
        (["arg1", "arg2"], 0),
    ])
    def test_main_parametrized(self, args, expected):
        """Test main function with various arguments."""
        result = main(args)
        assert result == expected
EOF

cat > tests/test_core.py << 'EOF'
"""Tests for core modules."""

import pytest
from src.project_name.core.utils import get_version, validate_config


def test_get_version():
    """Test get_version function."""
    version = get_version()
    assert isinstance(version, str)
    assert len(version) > 0


class TestValidateConfig:
    """Test validate_config function."""
    
    def test_valid_config(self, sample_config):
        """Test with valid configuration."""
        assert validate_config(sample_config) is True
    
    def test_missing_name(self, sample_config):
        """Test with missing name key."""
        del sample_config["name"]
        assert validate_config(sample_config) is False
    
    def test_missing_version(self, sample_config):
        """Test with missing version key."""
        del sample_config["version"]
        assert validate_config(sample_config) is False
    
    def test_empty_config(self):
        """Test with empty configuration."""
        assert validate_config({}) is False
    
    @pytest.mark.parametrize("config,expected", [
        ({"name": "test", "version": "1.0"}, True),
        ({"name": "test"}, False),
        ({"version": "1.0"}, False),
        ({}, False),
    ])
    def test_validate_config_parametrized(self, config, expected):
        """Test validate_config with various configurations."""
        assert validate_config(config) == expected
EOF

# Create documentation files
cat > docs/index.md << 'EOF'
# Project Name

A minimal Python project template with modern tooling.

## Overview

This project provides a solid foundation for Python applications with:

- Modern dependency management with UV
- Code quality tools (black, isort, flake8, mypy)
- Testing with pytest
- Pre-commit hooks
- CI/CD integration

## Installation

```bash
# Clone the repository
git clone https://github.com/your-org/project-name.git
cd project-name

# Set up the project
./scripts/setup.sh

# Activate virtual environment
source .venv/bin/activate
```

## Usage

```python
from src.project_name import main

# Run the main function
result = main()
```

## Development

See the [API Reference](api.md) for detailed documentation.
EOF

cat > docs/api.md << 'EOF'
# API Reference

::: src.project_name.main
    options:
      show_root_heading: true
      show_source: false

::: src.project_name.core.utils
    options:
      show_root_heading: true
      show_source: false
EOF

# Create example file
cat > examples/basic_usage.py << 'EOF'
#!/usr/bin/env python3
"""Basic usage example for the project."""

from src.project_name import main
from src.project_name.core.utils import get_version, validate_config


def main_example():
    """Demonstrate basic usage of the project."""
    print(f"Project version: {get_version()}")
    
    # Example configuration
    config = {
        "name": "example-app",
        "version": "1.0.0",
        "debug": True,
    }
    
    if validate_config(config):
        print("Configuration is valid")
    else:
        print("Configuration is invalid")
    
    # Run main function
    result = main(["--example"])
    print(f"Main function returned: {result}")


if __name__ == "__main__":
    main_example()
EOF

echo "Basic project structure generated successfully!"