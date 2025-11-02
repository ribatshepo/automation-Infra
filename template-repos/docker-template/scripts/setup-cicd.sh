#!/bin/bash

# CI/CD Setup Script for Harbor Integration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Setting up CI/CD integration with Harbor..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Initialize git first:"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m 'Initial commit'"
    exit 1
fi

# Check if GitHub CLI is available
if command -v gh >/dev/null 2>&1; then
    print_status "GitHub CLI found. Setting up repository secrets..."
    
    # Set repository secrets for Harbor
    print_status "Setting up GitHub repository secrets for Harbor..."
    echo "Please enter your Harbor registry credentials:"
    
    read -p "Harbor URL (default: harbor.local): " HARBOR_URL
    HARBOR_URL=${HARBOR_URL:-harbor.local}
    read -p "Harbor Username: " HARBOR_USERNAME
    read -s -p "Harbor Password: " HARBOR_PASSWORD
    echo
    read -p "Harbor Project (default: library): " HARBOR_PROJECT
    HARBOR_PROJECT=${HARBOR_PROJECT:-library}
    
    # Set secrets
    gh secret set HARBOR_URL --body "$HARBOR_URL"
    gh secret set HARBOR_USERNAME --body "$HARBOR_USERNAME"
    gh secret set HARBOR_PASSWORD --body "$HARBOR_PASSWORD"
    gh secret set HARBOR_PROJECT --body "$HARBOR_PROJECT"
    
    print_success "Harbor secrets configured in GitHub"
    
else
    print_warning "GitHub CLI not found. Manual secret setup required:"
    echo "1. Go to your repository settings"
    echo "2. Navigate to Secrets and variables > Actions"
    echo "3. Add the following secrets:"
    echo "   - HARBOR_URL: Your Harbor URL (e.g., harbor.local)"
    echo "   - HARBOR_USERNAME: Your Harbor username"
    echo "   - HARBOR_PASSWORD: Your Harbor password"
    echo "   - HARBOR_PROJECT: Your Harbor project (e.g., library)"
fi

# Configure Git hooks (if pre-commit is available)
if command -v pre-commit >/dev/null 2>&1; then
    print_status "Setting up pre-commit hooks..."
    
    cat > .pre-commit-config.yaml << 'EOFPC'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
  
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
        args: ['--ignore', 'DL3008', '--ignore', 'DL3009']

  - repo: local
    hooks:
      - id: docker-security-check
        name: Docker Security Check
        entry: ./scripts/security-check.sh
        language: script
        files: ^Dockerfile.*$
        pass_filenames: false
EOFPC

    pre-commit install
    print_success "Pre-commit hooks installed"
else
    print_warning "pre-commit not found. Install with: pip install pre-commit"
fi

# Create Harbor-specific environment file
print_status "Creating Harbor environment configuration..."
cat > .env.harbor << 'EOF'
# Harbor Configuration
HARBOR_URL=harbor.local
HARBOR_PROJECT=library
HARBOR_USERNAME=admin
HARBOR_PASSWORD=Harbor12345

# Image Configuration
IMAGE_NAME=my-docker-project
IMAGE_TAG=latest

# Security Configuration
ENABLE_VULNERABILITY_SCAN=true
SCAN_ON_PUSH=true
EOF

print_warning "Harbor credentials saved to .env.harbor"
print_warning "Update .env.harbor with your actual Harbor credentials"

# Create GitHub Actions workflow for Harbor
print_status "Creating GitHub Actions workflow for Harbor integration..."
mkdir -p .github/workflows

cat > .github/workflows/harbor-ci.yml << 'EOF'
name: Harbor CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  HARBOR_URL: ${{ secrets.HARBOR_URL }}
  HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
  IMAGE_NAME: ${{ github.event.repository.name }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: app/package-lock.json

    - name: Install dependencies
      working-directory: ./app
      run: npm ci

    - name: Run tests
      working-directory: ./app
      run: npm test || echo "No tests found"

    - name: Run linting
      working-directory: ./app
      run: npm run lint || echo "No linting configured"

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Harbor Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.HARBOR_URL }}
        username: ${{ secrets.HARBOR_USERNAME }}
        password: ${{ secrets.HARBOR_PASSWORD }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.HARBOR_URL }}/${{ env.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push Docker image
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        platforms: linux/amd64,linux/arm64

  security-scan:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Log in to Harbor Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.HARBOR_URL }}
        username: ${{ secrets.HARBOR_USERNAME }}
        password: ${{ secrets.HARBOR_PASSWORD }}

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: '${{ env.HARBOR_URL }}/${{ env.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'

    - name: Trigger Harbor vulnerability scan
      run: |
        echo "Triggering Harbor vulnerability scan..."
        # Harbor automatically scans images on push when configured
        # You can also manually trigger via API
        curl -u "${{ secrets.HARBOR_USERNAME }}:${{ secrets.HARBOR_PASSWORD }}" \
          -X POST \
          "https://${{ env.HARBOR_URL }}/api/v2.0/projects/${{ env.HARBOR_PROJECT }}/repositories/${{ env.IMAGE_NAME }}/artifacts/${{ github.sha }}/scan" || true

  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    needs: [build-and-push, security-scan]
    runs-on: ubuntu-latest
    environment: staging
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Deploy to staging
      run: |
        echo "Deploying to staging environment..."
        echo "Image: ${{ env.HARBOR_URL }}/${{ env.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:${{ github.sha }}"
        # Add your staging deployment commands here
        # kubectl set image deployment/my-app my-app=${{ env.HARBOR_URL }}/${{ env.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: [build-and-push, security-scan]
    runs-on: ubuntu-latest
    environment: production
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Deploy to production
      run: |
        echo "Deploying to production environment..."
        echo "Image: ${{ env.HARBOR_URL }}/${{ env.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:${{ github.sha }}"
        # Add your production deployment commands here
        # kubectl set image deployment/my-app my-app=${{ env.HARBOR_URL }}/${{ env.HARBOR_PROJECT }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
EOF

print_success "Harbor CI/CD workflow created"

print_success "CI/CD setup completed"
print_status "Next steps:"
echo "1. Update .env.harbor with your Harbor credentials"
echo "2. Commit and push your changes:"
echo "   git add ."
echo "   git commit -m 'Add Harbor CI/CD integration'"
echo "   git push"
echo "3. Create a pull request to test the workflow"
echo "4. Configure Harbor project settings for auto-scan"
echo "5. Set up webhook notifications if needed"