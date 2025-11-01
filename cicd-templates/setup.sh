#!/bin/bash
set -euo pipefail

# Universal CI/CD Templates Setup Script
# This script helps you integrate the CI/CD templates into your project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$(pwd)}"

# Logging function
log() {
    echo -e "${1}" >&2
}

# Show header
show_header() {
    log "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    log "${PURPLE}║              Universal CI/CD Templates Setup                 ║${NC}"
    log "${PURPLE}║            Harbor + JFrog Artifactory Integration            ║${NC}"
    log "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    log ""
}

# Detect project type
detect_project_type() {
    local project_dir="$1"
    local detected_types=()
    
    log "${BLUE} Detecting project type in: ${project_dir}${NC}"
    
    # Check for different project types
    if [[ -f "${project_dir}/package.json" ]]; then
        detected_types+=("nodejs")
        log "${GREEN}  ✓ Node.js project detected (package.json)${NC}"
    fi
    
    if [[ -f "${project_dir}/requirements.txt" ]] || [[ -f "${project_dir}/pyproject.toml" ]] || [[ -f "${project_dir}/setup.py" ]]; then
        detected_types+=("python")
        log "${GREEN}  ✓ Python project detected${NC}"
    fi
    
    if [[ -f "${project_dir}/go.mod" ]]; then
        detected_types+=("golang")
        log "${GREEN}  ✓ Go project detected (go.mod)${NC}"
    fi
    
    if [[ -f "${project_dir}/Cargo.toml" ]]; then
        detected_types+=("rust")
        log "${GREEN}  ✓ Rust project detected (Cargo.toml)${NC}"
    fi
    
    if find "${project_dir}" -name "*.csproj" -o -name "*.sln" | grep -q .; then
        detected_types+=("dotnet")
        log "${GREEN}  ✓ .NET project detected${NC}"
    fi
    
    if [[ -f "${project_dir}/Dockerfile" ]]; then
        detected_types+=("docker")
        log "${GREEN}  ✓ Docker project detected (Dockerfile)${NC}"
    fi
    
    if [[ ${#detected_types[@]} -eq 0 ]]; then
        log "${YELLOW}  ⚠ No specific project type detected, will offer generic options${NC}"
        detected_types+=("docker")
    fi
    
    echo "${detected_types[@]}"
}

# Copy workflow files
copy_workflow() {
    local workflow_type="$1"
    local target_dir="$2"
    
    log "${BLUE} Setting up ${workflow_type} workflow...${NC}"
    
    # Create .github/workflows directory
    mkdir -p "${target_dir}/.github/workflows"
    mkdir -p "${target_dir}/.github/actions"
    
    # Copy workflow file
    if [[ -f "${SCRIPT_DIR}/.github/workflows/${workflow_type}.yml" ]]; then
        cp "${SCRIPT_DIR}/.github/workflows/${workflow_type}.yml" "${target_dir}/.github/workflows/"
        log "${GREEN}  ✓ Copied ${workflow_type}.yml workflow${NC}"
    else
        log "${RED}  ✗ Workflow file not found: ${workflow_type}.yml${NC}"
        return 1
    fi
    
    # Copy custom actions
    if [[ -d "${SCRIPT_DIR}/.github/actions" ]]; then
        cp -r "${SCRIPT_DIR}/.github/actions/"* "${target_dir}/.github/actions/"
        log "${GREEN}  ✓ Copied custom actions${NC}"
    fi
}

# Create workflow configuration
create_workflow_config() {
    local workflow_type="$1"
    local target_dir="$2"
    
    log "${BLUE} Creating workflow configuration for ${workflow_type}...${NC}"
    
    local workflow_file="${target_dir}/.github/workflows/ci-cd.yml"
    
    cat > "${workflow_file}" << EOF
name: 'CI/CD Pipeline'

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master ]
  release:
    types: [ published ]

jobs:
  build-and-deploy:
    uses: ./.github/workflows/${workflow_type}.yml
    with:
      environment: \${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
      run-tests: true
      run-security-scan: true
      deploy-package: \${{ github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/') }}
      build-docker: true
    secrets:
      HARBOR_REGISTRY: \${{ secrets.HARBOR_REGISTRY }}
      HARBOR_USERNAME: \${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: \${{ secrets.HARBOR_PASSWORD }}
      HARBOR_PROJECT: \${{ secrets.HARBOR_PROJECT }}
      ARTIFACTORY_URL: \${{ secrets.ARTIFACTORY_URL }}
      ARTIFACTORY_USERNAME: \${{ secrets.ARTIFACTORY_USERNAME }}
      ARTIFACTORY_PASSWORD: \${{ secrets.ARTIFACTORY_PASSWORD }}
      ARTIFACTORY_$(echo ${workflow_type^^} | tr '-' '_')_REPO: \${{ secrets.ARTIFACTORY_$(echo ${workflow_type^^} | tr '-' '_')_REPO }}
EOF

    log "${GREEN}  ✓ Created ci-cd.yml configuration${NC}"
}

# Generate secrets template
generate_secrets_template() {
    local target_dir="$1"
    
    log "${BLUE} Generating secrets template...${NC}"
    
    cat > "${target_dir}/github-secrets-template.md" << EOF
# GitHub Secrets Configuration

Add these secrets to your GitHub repository:
\`Settings → Secrets and variables → Actions → Repository secrets\`

## Harbor (Container Registry)
\`\`\`
HARBOR_REGISTRY=your-harbor-instance.com
HARBOR_USERNAME=your-harbor-user
HARBOR_PASSWORD=your-harbor-password-or-token
HARBOR_PROJECT=your-project-name
\`\`\`

## JFrog Artifactory (Package Registry)
\`\`\`
ARTIFACTORY_URL=https://your-artifactory-instance.com
ARTIFACTORY_USERNAME=your-artifactory-user
ARTIFACTORY_PASSWORD=your-artifactory-password
ARTIFACTORY_ACCESS_TOKEN=your-access-token (optional, alternative to username/password)
\`\`\`

## Repository-specific secrets
\`\`\`
ARTIFACTORY_NUGET_REPO=nuget-local      # For .NET projects
ARTIFACTORY_PYPI_REPO=pypi-local        # For Python projects
ARTIFACTORY_NPM_REPO=npm-local          # For Node.js projects
ARTIFACTORY_GO_REPO=go-local            # For Go projects
ARTIFACTORY_CARGO_REPO=cargo-local      # For Rust projects
ARTIFACTORY_GENERIC_REPO=generic-local  # For generic packages
\`\`\`

## Example Values
Based on your ansible-infra setup:
\`\`\`
HARBOR_REGISTRY=10.100.10.215:8080
HARBOR_USERNAME=admin
HARBOR_PASSWORD=Harbor12345!
HARBOR_PROJECT=library

ARTIFACTORY_URL=http://10.100.10.215:8081
ARTIFACTORY_USERNAME=admin
ARTIFACTORY_PASSWORD=Admin123!
\`\`\`
EOF

    log "${GREEN}  ✓ Created github-secrets-template.md${NC}"
}

# Create Dockerfile template
create_dockerfile_template() {
    local project_type="$1"
    local target_dir="$2"
    
    if [[ -f "${target_dir}/Dockerfile" ]]; then
        log "${YELLOW}  ⚠ Dockerfile already exists, skipping template creation${NC}"
        return
    fi
    
    log "${BLUE} Creating Dockerfile template for ${project_type}...${NC}"
    
    case "${project_type}" in
        "nodejs")
            cat > "${target_dir}/Dockerfile" << 'EOF'
# Node.js Dockerfile Template
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 8080
USER node
CMD ["npm", "start"]
EOF
            ;;
        "python")
            cat > "${target_dir}/Dockerfile" << 'EOF'
# Python Dockerfile Template
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY . .
EXPOSE 8080
USER nobody
CMD ["python", "app.py"]
EOF
            ;;
        "golang")
            cat > "${target_dir}/Dockerfile" << 'EOF'
# Go Dockerfile Template
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app ./cmd/...

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/app .
EXPOSE 8080
CMD ["./app"]
EOF
            ;;
        "rust")
            cat > "${target_dir}/Dockerfile" << 'EOF'
# Rust Dockerfile Template
FROM rust:1.75-slim AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/app .
EXPOSE 8080
CMD ["./app"]
EOF
            ;;
        "dotnet")
            cat > "${target_dir}/Dockerfile" << 'EOF'
# .NET Dockerfile Template
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "YourApp.dll"]
EOF
            ;;
        *)
            cat > "${target_dir}/Dockerfile" << 'EOF'
# Generic Dockerfile Template
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["./app"]
EOF
            ;;
    esac
    
    log "${GREEN}  ✓ Created Dockerfile template${NC}"
}

# Interactive setup
interactive_setup() {
    local target_dir="$1"
    local detected_types=($(detect_project_type "$target_dir"))
    
    log ""
    log "${YELLOW} Select project types to set up (space-separated numbers):${NC}"
    
    local options=("dotnet" "python" "golang" "rust" "nodejs" "docker")
    local i=1
    
    for option in "${options[@]}"; do
        local status=""
        if [[ " ${detected_types[@]} " =~ " ${option} " ]]; then
            status=" ${GREEN}(detected)${NC}"
        fi
        log "${BLUE}  ${i}) ${option}${status}${NC}"
        ((i++))
    done
    
    log ""
    read -p "Enter your choices (e.g., 1 2 3): " -a choices
    
    log ""
    log "${BLUE} Setting up selected workflows...${NC}"
    
    for choice in "${choices[@]}"; do
        if [[ "$choice" =~ ^[1-6]$ ]]; then
            local workflow_type="${options[$((choice-1))]}"
            log ""
            log "${PURPLE}Setting up ${workflow_type} workflow...${NC}"
            
            copy_workflow "$workflow_type" "$target_dir"
            create_workflow_config "$workflow_type" "$target_dir"
            create_dockerfile_template "$workflow_type" "$target_dir"
        else
            log "${RED}  ✗ Invalid choice: $choice${NC}"
        fi
    done
    
    generate_secrets_template "$target_dir"
}

# Automatic setup based on detection
automatic_setup() {
    local target_dir="$1"
    local detected_types=($(detect_project_type "$target_dir"))
    
    log ""
    log "${BLUE} Setting up workflows automatically based on detected project types...${NC}"
    
    for workflow_type in "${detected_types[@]}"; do
        log ""
        log "${PURPLE}Setting up ${workflow_type} workflow...${NC}"
        
        copy_workflow "$workflow_type" "$target_dir"
        create_workflow_config "$workflow_type" "$target_dir"
        create_dockerfile_template "$workflow_type" "$target_dir"
    done
    
    generate_secrets_template "$target_dir"
}

# Show help
show_help() {
    cat << EOF
Universal CI/CD Templates Setup Script

Usage: $0 [TARGET_DIR] [OPTIONS]

Options:
  -i, --interactive    Interactive mode (select workflows manually)
  -a, --automatic     Automatic mode (based on project detection)
  -h, --help          Show this help message

Arguments:
  TARGET_DIR          Target directory for setup (default: current directory)

Examples:
  $0                          # Setup in current directory (interactive)
  $0 /path/to/project -a     # Automatic setup in specified directory
  $0 . -i                    # Interactive setup in current directory

Supported Technologies:
  - .NET (NuGet packages → Artifactory, Docker → Harbor)
  - Python (PyPI packages → Artifactory, Docker → Harbor)
  - Go (Go modules → Artifactory, Docker → Harbor)
  - Rust (Cargo crates → Artifactory, Docker → Harbor)
  - Node.js (npm packages → Artifactory, Docker → Harbor)
  - Docker (containers → Harbor)

EOF
}

# Main function
main() {
    local mode="interactive"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interactive)
                mode="interactive"
                shift
                ;;
            -a|--automatic)
                mode="automatic"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                TARGET_DIR="$1"
                shift
                ;;
        esac
    done
    
    show_header
    
    # Validate target directory
    if [[ ! -d "$TARGET_DIR" ]]; then
        log "${RED} Target directory does not exist: $TARGET_DIR${NC}"
        exit 1
    fi
    
    log "${BLUE} Target directory: $TARGET_DIR${NC}"
    
    # Run setup based on mode
    if [[ "$mode" == "interactive" ]]; then
        interactive_setup "$TARGET_DIR"
    else
        automatic_setup "$TARGET_DIR"
    fi
    
    # Summary
    log ""
    log "${GREEN} Setup completed successfully!${NC}"
    log ""
    log "${YELLOW} Next steps:${NC}"
    log "${BLUE}  1. Review the generated workflow files in .github/workflows/${NC}"
    log "${BLUE}  2. Configure GitHub secrets using github-secrets-template.md${NC}"
    log "${BLUE}  3. Customize Dockerfile if needed${NC}"
    log "${BLUE}  4. Commit and push to trigger the CI/CD pipeline${NC}"
    log ""
    log "${PURPLE} Documentation: https://github.com/your-org/cicd-templates${NC}"
}

# Run main function
main "$@"