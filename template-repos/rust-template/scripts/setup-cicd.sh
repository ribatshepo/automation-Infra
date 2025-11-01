#!/bin/bash

# CI/CD setup script for Rust projects
# Configures GitHub Actions and other CI/CD tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to setup GitHub Actions
setup_github_actions() {
    print_status "Setting up GitHub Actions..."
    
    # Check if .github/workflows exists
    if [ ! -d ".github/workflows" ]; then
        mkdir -p .github/workflows
        print_success "Created .github/workflows directory"
    fi
    
    # Check if CI workflow already exists
    if [ -f ".github/workflows/ci.yml" ]; then
        print_success "GitHub Actions CI workflow already exists"
    else
        print_warning "GitHub Actions CI workflow not found"
        print_status "Please ensure ci.yml is properly configured"
    fi
    
    # Create additional workflow files if needed
    create_release_workflow
    create_security_workflow
}

# Function to create release workflow
create_release_workflow() {
    if [ ! -f ".github/workflows/release.yml" ]; then
        print_status "Creating release workflow..."
        
        cat > .github/workflows/release.yml << 'EOF'
name: Release

on:
  push:
    tags:
      - 'v*'

env:
  CARGO_TERM_COLOR: always

jobs:
  release:
    name: Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          override: true
      
      - name: Cache cargo registry
        uses: actions/cache@v3
        with:
          path: ~/.cargo/registry
          key: ${{ runner.os }}-cargo-registry-${{ hashFiles('**/Cargo.lock') }}
      
      - name: Build release
        run: cargo build --release
      
      - name: Run tests
        run: cargo test --release
      
      - name: Create release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false

  build-and-upload:
    name: Build and upload
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        include:
          - build: linux
            os: ubuntu-latest
            target: x86_64-unknown-linux-musl
          - build: windows
            os: windows-latest
            target: x86_64-pc-windows-msvc
          - build: macos
            os: macos-latest
            target: x86_64-apple-darwin
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          target: ${{ matrix.target }}
          override: true
      
      - name: Build target
        run: cargo build --release --target ${{ matrix.target }}
      
      - name: Prepare artifacts
        shell: bash
        run: |
          cd target/${{ matrix.target }}/release
          if [[ "${{ matrix.os }}" == "windows-latest" ]]; then
            BINARY_NAME="$(ls *.exe | head -1)"
            echo "BINARY_NAME=$BINARY_NAME" >> $GITHUB_ENV
            echo "ASSET_NAME=${{ matrix.build }}-$BINARY_NAME" >> $GITHUB_ENV
          else
            BINARY_NAME="$(ls | grep -v '\.d$' | head -1)"
            echo "BINARY_NAME=$BINARY_NAME" >> $GITHUB_ENV
            echo "ASSET_NAME=${{ matrix.build }}-$BINARY_NAME" >> $GITHUB_ENV
          fi
      
      - name: Upload binaries to release
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ needs.release.outputs.upload_url }}
          asset_path: target/${{ matrix.target }}/release/${{ env.BINARY_NAME }}
          asset_name: ${{ env.ASSET_NAME }}
          asset_content_type: application/octet-stream
EOF
        
        print_success "Created release workflow"
    fi
}

# Function to create security workflow
create_security_workflow() {
    if [ ! -f ".github/workflows/security.yml" ]; then
        print_status "Creating security workflow..."
        
        cat > .github/workflows/security.yml << 'EOF'
name: Security Audit

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  security:
    name: Security Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          override: true
      
      - name: Install security tools
        run: |
          cargo install cargo-audit
          cargo install cargo-deny
      
      - name: Run security audit
        run: cargo audit
      
      - name: Run dependency check
        run: cargo deny check
        continue-on-error: true
      
      - name: Check for unsafe code
        run: |
          if grep -r "unsafe" src/ --include="*.rs" | grep -v "// Safe:" | grep -v "# Safety"; then
            echo "Unsafe code found - please review carefully"
            exit 1
          else
            echo "No unsafe code detected"
          fi
        continue-on-error: true
EOF
        
        print_success "Created security workflow"
    fi
}

# Function to setup repository secrets
setup_repository_secrets() {
    print_status "Setting up repository secrets..."
    
    if command -v gh >/dev/null 2>&1; then
        print_status "GitHub CLI detected. You can set secrets using:"
        echo ""
        echo "  gh secret set HARBOR_USERNAME"
        echo "  gh secret set HARBOR_PASSWORD"
        echo "  gh secret set CARGO_REGISTRY_TOKEN"
        echo ""
        print_status "Or set them manually in your repository settings."
    else
        print_warning "GitHub CLI not found. Please set the following secrets manually:"
        echo ""
        echo "Required secrets for CI/CD:"
        echo "• HARBOR_USERNAME - Harbor registry username"
        echo "• HARBOR_PASSWORD - Harbor registry password"
        echo "• CARGO_REGISTRY_TOKEN - Cargo registry token (for publishing)"
        echo ""
        print_status "Set these in your repository Settings -> Secrets and variables -> Actions"
    fi
}

# Function to create dependabot configuration
setup_dependabot() {
    print_status "Setting up Dependabot..."
    
    if [ ! -d ".github" ]; then
        mkdir -p .github
    fi
    
    if [ ! -f ".github/dependabot.yml" ]; then
        cat > .github/dependabot.yml << 'EOF'
version: 2
updates:
  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "your-username"  # Replace with actual username
    labels:
      - "dependencies"
      - "rust"
    commit-message:
      prefix: "cargo"
      include: "scope"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "your-username"  # Replace with actual username
    labels:
      - "dependencies"
      - "github-actions"
    commit-message:
      prefix: "ci"
      include: "scope"
EOF
        
        print_success "Created Dependabot configuration"
        print_warning "Please update the reviewers field with your GitHub username"
    else
        print_success "Dependabot configuration already exists"
    fi
}

# Function to create issue templates
setup_issue_templates() {
    print_status "Setting up issue templates..."
    
    local template_dir=".github/ISSUE_TEMPLATE"
    
    if [ ! -d "$template_dir" ]; then
        mkdir -p "$template_dir"
    fi
    
    # Bug report template
    if [ ! -f "$template_dir/bug_report.md" ]; then
        cat > "$template_dir/bug_report.md" << 'EOF'
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment (please complete the following information):**
- OS: [e.g. Ubuntu 20.04, Windows 10, macOS Big Sur]
- Rust version: [e.g. 1.70.0]
- Project version: [e.g. 0.1.0]

**Additional context**
Add any other context about the problem here.

**Logs**
If applicable, add logs to help explain your problem.
EOF
        
        print_success "Created bug report template"
    fi
    
    # Feature request template
    if [ ! -f "$template_dir/feature_request.md" ]; then
        cat > "$template_dir/feature_request.md" << 'EOF'
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOF
        
        print_success "Created feature request template"
    fi
}

# Function to create pull request template
setup_pr_template() {
    print_status "Setting up pull request template..."
    
    if [ ! -f ".github/pull_request_template.md" ]; then
        cat > .github/pull_request_template.md << 'EOF'
## Description

Please include a summary of the changes and the related issue. Please also include relevant motivation and context.

Fixes # (issue)

## Type of change

Please delete options that are not relevant.

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## How Has This Been Tested?

Please describe the tests that you ran to verify your changes. Provide instructions so we can reproduce.

- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Checklist:

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
EOF
        
        print_success "Created pull request template"
    else
        print_success "Pull request template already exists"
    fi
}

# Function to create codecov configuration
setup_codecov() {
    print_status "Setting up Codecov configuration..."
    
    if [ ! -f "codecov.yml" ]; then
        cat > codecov.yml << 'EOF'
coverage:
  status:
    project:
      default:
        target: 80%
        threshold: 5%
    patch:
      default:
        target: 80%
        threshold: 5%

comment:
  layout: "reach,diff,flags,files,footer"
  behavior: default
  require_changes: false

ignore:
  - "tests/"
  - "benches/"
  - "examples/"
EOF
        
        print_success "Created Codecov configuration"
    else
        print_success "Codecov configuration already exists"
    fi
}

# Function to show next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}🚀 CI/CD Setup Complete!${NC}"
    echo "======================================"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Push your changes to GitHub"
    echo "2. Set up repository secrets (see above)"
    echo "3. Update issue templates with your information"
    echo "4. Configure branch protection rules"
    echo "5. Enable Dependabot security updates"
    echo "6. Set up Codecov if using coverage reporting"
    echo ""
    echo -e "${BLUE}Branch Protection Recommendations:${NC}"
    echo "• Require pull request reviews"
    echo "• Require status checks to pass"
    echo "• Require branches to be up to date"
    echo "• Include administrators"
    echo ""
    echo -e "${BLUE}Status Checks to Require:${NC}"
    echo "• test (from CI workflow)"
    echo "• security (from security workflow)"
    echo ""
}

# Main function
main() {
    echo -e "${BLUE}🦀 Rust CI/CD Setup${NC}"
    echo "======================================"
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        print_error "This doesn't appear to be a git repository"
        print_status "Initialize git first: git init"
        exit 1
    fi
    
    # Setup GitHub Actions
    setup_github_actions
    
    # Setup repository secrets
    setup_repository_secrets
    
    # Setup Dependabot
    setup_dependabot
    
    # Setup issue templates
    setup_issue_templates
    
    # Setup PR template
    setup_pr_template
    
    # Setup Codecov
    setup_codecov
    
    show_next_steps
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo ""
        echo "This script sets up CI/CD for Rust projects including:"
        echo "• GitHub Actions workflows (CI, release, security)"
        echo "• Dependabot configuration"
        echo "• Issue and PR templates"
        echo "• Codecov configuration"
        echo "• Repository secrets setup instructions"
        echo ""
        echo "The script should be run from the root of your git repository."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac