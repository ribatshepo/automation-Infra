#!/bin/bash
set -e

echo "Running security checks..."

# Activate virtual environment if available
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

echo "Checking for known security vulnerabilities..."
uv run safety check

echo "Running bandit security analysis..."
uv run bandit -r src/ -f json -o security-report.json || true
uv run bandit -r src/

echo "Checking for secrets in code..."
if command -v detect-secrets &> /dev/null; then
    detect-secrets scan --all-files --disable-plugin AbsolutePathDetectorPlugin
else
    echo "detect-secrets not installed, skipping secret detection"
fi

echo "Security checks complete!"
echo "Security report saved to security-report.json"