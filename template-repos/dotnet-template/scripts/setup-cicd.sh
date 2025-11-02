#!/bin/bash

# .NET CI/CD setup script
set -e

echo "[INFO] Setting up .NET CI/CD..."

# Create .github/workflows directory if it doesn't exist
mkdir -p .github/workflows

# Create basic CI workflow
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: automation-infra/cicd-templates/.github/workflows/main-dotnet-deploy.yml@main
    with:
      dotnet_version: "8.0.x"
      project_name: "dotnet-template"
      run_tests: true
      run_code_analysis: true
      run_security_scan: true
      publish_packages: false
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
EOF

echo "[SUCCESS] CI/CD setup completed"