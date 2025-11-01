#!/bin/bash
set -euo pipefail

# GitHub Secrets Configuration Script
# This script helps you configure GitHub repository secrets for CI/CD

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values from your infrastructure
DEFAULT_HARBOR_REGISTRY="10.100.10.215:8080"
DEFAULT_HARBOR_USERNAME="admin"
DEFAULT_HARBOR_PASSWORD="Harbor12345!"
DEFAULT_HARBOR_PROJECT="library"

DEFAULT_ARTIFACTORY_URL="http://10.100.10.215:8081"
DEFAULT_ARTIFACTORY_USERNAME="admin"
DEFAULT_ARTIFACTORY_PASSWORD="Admin123!"

# Repository configurations
DEFAULT_NUGET_REPO="nuget-local"
DEFAULT_PYPI_REPO="pypi-local"
DEFAULT_NPM_REPO="npm-local"
DEFAULT_GO_REPO="go-local"
DEFAULT_CARGO_REPO="cargo-local"
DEFAULT_GENERIC_REPO="generic-local"

# Logging function
log() {
    echo -e "${1}" >&2
}

# Show header
show_header() {
    log "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    log "${PURPLE}║                GitHub Secrets Configuration                  ║${NC}"
    log "${PURPLE}║            Harbor + JFrog Artifactory Integration            ║${NC}"
    log "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    log ""
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --interactive, -i     Interactive mode with prompts
    --template, -t        Generate secrets template file only
    --github-cli, -g      Use GitHub CLI to set secrets directly
    --repository, -r      GitHub repository (owner/repo) for direct setup
    --help, -h           Show this help message

Examples:
    $0 --interactive                    # Interactive configuration
    $0 --template                       # Generate template file
    $0 --github-cli -r owner/repo       # Direct GitHub CLI setup
    $0 --github-cli -r owner/repo -i    # Interactive + direct setup

EOF
}

# Generate secrets template file
generate_template() {
    local output_file="github-secrets-configuration.md"
    
    log "${BLUE} Generating GitHub secrets template...${NC}"
    
    cat > "${output_file}" << EOF
# GitHub Repository Secrets Configuration

## Required Secrets

Add these secrets to your GitHub repository:
**Path:** \`Settings → Secrets and variables → Actions → Repository secrets\`

### Harbor (Container Registry)
| Secret Name | Value | Description |
|-------------|-------|-------------|
| \`HARBOR_REGISTRY\` | \`${DEFAULT_HARBOR_REGISTRY}\` | Harbor registry URL |
| \`HARBOR_USERNAME\` | \`${DEFAULT_HARBOR_USERNAME}\` | Harbor username |
| \`HARBOR_PASSWORD\` | \`${DEFAULT_HARBOR_PASSWORD}\` | Harbor password |
| \`HARBOR_PROJECT\` | \`${DEFAULT_HARBOR_PROJECT}\` | Harbor project name |

### JFrog Artifactory (Package Registry)
| Secret Name | Value | Description |
|-------------|-------|-------------|
| \`ARTIFACTORY_URL\` | \`${DEFAULT_ARTIFACTORY_URL}\` | Artifactory instance URL |
| \`ARTIFACTORY_USERNAME\` | \`${DEFAULT_ARTIFACTORY_USERNAME}\` | Artifactory username |
| \`ARTIFACTORY_PASSWORD\` | \`${DEFAULT_ARTIFACTORY_PASSWORD}\` | Artifactory password |

### Repository Configuration (Technology-Specific)
| Secret Name | Value | Technology | Description |
|-------------|-------|------------|-------------|
| \`ARTIFACTORY_NUGET_REPO\` | \`${DEFAULT_NUGET_REPO}\` | .NET | NuGet package repository |
| \`ARTIFACTORY_PYPI_REPO\` | \`${DEFAULT_PYPI_REPO}\` | Python | PyPI package repository |
| \`ARTIFACTORY_NPM_REPO\` | \`${DEFAULT_NPM_REPO}\` | Node.js | npm package repository |
| \`ARTIFACTORY_GO_REPO\` | \`${DEFAULT_GO_REPO}\` | Go | Go modules repository |
| \`ARTIFACTORY_CARGO_REPO\` | \`${DEFAULT_CARGO_REPO}\` | Rust | Cargo package repository |
| \`ARTIFACTORY_GENERIC_REPO\` | \`${DEFAULT_GENERIC_REPO}\` | Generic | Generic artifacts repository |

## Quick Setup Commands

### Option 1: Manual Setup (GitHub Web UI)
1. Go to your repository on GitHub
2. Navigate to: \`Settings → Secrets and variables → Actions\`
3. Click \`New repository secret\`
4. Add each secret from the table above

### Option 2: GitHub CLI (Automated)
\`\`\`bash
# Set Harbor secrets
gh secret set HARBOR_REGISTRY --body "${DEFAULT_HARBOR_REGISTRY}"
gh secret set HARBOR_USERNAME --body "${DEFAULT_HARBOR_USERNAME}"
gh secret set HARBOR_PASSWORD --body "${DEFAULT_HARBOR_PASSWORD}"
gh secret set HARBOR_PROJECT --body "${DEFAULT_HARBOR_PROJECT}"

# Set JFrog Artifactory secrets
gh secret set ARTIFACTORY_URL --body "${DEFAULT_ARTIFACTORY_URL}"
gh secret set ARTIFACTORY_USERNAME --body "${DEFAULT_ARTIFACTORY_USERNAME}"
gh secret set ARTIFACTORY_PASSWORD --body "${DEFAULT_ARTIFACTORY_PASSWORD}"

# Set repository-specific secrets
gh secret set ARTIFACTORY_NUGET_REPO --body "${DEFAULT_NUGET_REPO}"
gh secret set ARTIFACTORY_PYPI_REPO --body "${DEFAULT_PYPI_REPO}"
gh secret set ARTIFACTORY_NPM_REPO --body "${DEFAULT_NPM_REPO}"
gh secret set ARTIFACTORY_GO_REPO --body "${DEFAULT_GO_REPO}"
gh secret set ARTIFACTORY_CARGO_REPO --body "${DEFAULT_CARGO_REPO}"
gh secret set ARTIFACTORY_GENERIC_REPO --body "${DEFAULT_GENERIC_REPO}"
\`\`\`

### Option 3: Environment Variables (for testing)
\`\`\`bash
export HARBOR_REGISTRY="${DEFAULT_HARBOR_REGISTRY}"
export HARBOR_USERNAME="${DEFAULT_HARBOR_USERNAME}"
export HARBOR_PASSWORD="${DEFAULT_HARBOR_PASSWORD}"
export HARBOR_PROJECT="${DEFAULT_HARBOR_PROJECT}"
export ARTIFACTORY_URL="${DEFAULT_ARTIFACTORY_URL}"
export ARTIFACTORY_USERNAME="${DEFAULT_ARTIFACTORY_USERNAME}"
export ARTIFACTORY_PASSWORD="${DEFAULT_ARTIFACTORY_PASSWORD}"
export ARTIFACTORY_NUGET_REPO="${DEFAULT_NUGET_REPO}"
export ARTIFACTORY_PYPI_REPO="${DEFAULT_PYPI_REPO}"
export ARTIFACTORY_NPM_REPO="${DEFAULT_NPM_REPO}"
export ARTIFACTORY_GO_REPO="${DEFAULT_GO_REPO}"
export ARTIFACTORY_CARGO_REPO="${DEFAULT_CARGO_REPO}"
export ARTIFACTORY_GENERIC_REPO="${DEFAULT_GENERIC_REPO}"
\`\`\`

## Security Notes

1. **Harbor Password**: Consider using Robot Accounts for better security
2. **Artifactory Access**: Use Access Tokens instead of passwords when possible
3. **Repository Access**: Ensure secrets have minimal required permissions
4. **Secret Rotation**: Regularly rotate passwords and tokens

##  Testing Your Configuration

After setting up secrets, test with a simple workflow:

\`\`\`yaml
name: Test Secrets
on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Test Harbor Connection
        run: |
          echo "Harbor Registry: \${{ secrets.HARBOR_REGISTRY }}"
          echo "Harbor Project: \${{ secrets.HARBOR_PROJECT }}"
          
      - name: Test Artifactory Connection
        run: |
          echo "Artifactory URL: \${{ secrets.ARTIFACTORY_URL }}"
          echo "Artifactory User: \${{ secrets.ARTIFACTORY_USERNAME }}"
\`\`\`

## Troubleshooting

### Common Issues:
1. **Invalid Harbor URL**: Ensure port 8080 is accessible
2. **Artifactory Authentication**: Verify username/password combination
3. **Repository Not Found**: Ensure repositories exist in Artifactory
4. **Network Access**: Check firewall rules for CI/CD runners

### Verification Commands:
\`\`\`bash
# Test Harbor connectivity
docker login ${DEFAULT_HARBOR_REGISTRY} -u ${DEFAULT_HARBOR_USERNAME}

# Test Artifactory connectivity
curl -u ${DEFAULT_ARTIFACTORY_USERNAME}:${DEFAULT_ARTIFACTORY_PASSWORD} ${DEFAULT_ARTIFACTORY_URL}/artifactory/api/system/ping

# List Artifactory repositories
curl -u ${DEFAULT_ARTIFACTORY_USERNAME}:${DEFAULT_ARTIFACTORY_PASSWORD} ${DEFAULT_ARTIFACTORY_URL}/artifactory/api/repositories
\`\`\`

---
Generated by: Universal CI/CD Templates Configuration Script
Date: $(date)
EOF

    log "${GREEN} Generated: ${output_file}${NC}"
    log "${CYAN} View the file for complete setup instructions${NC}"
}

# Interactive configuration
interactive_setup() {
    log "${YELLOW}🎯 Interactive GitHub Secrets Configuration${NC}"
    log ""
    
    # Collect Harbor settings
    log "${BLUE}Harbor Configuration:${NC}"
    read -p "Harbor Registry [${DEFAULT_HARBOR_REGISTRY}]: " harbor_registry
    harbor_registry=${harbor_registry:-$DEFAULT_HARBOR_REGISTRY}
    
    read -p "Harbor Username [${DEFAULT_HARBOR_USERNAME}]: " harbor_username
    harbor_username=${harbor_username:-$DEFAULT_HARBOR_USERNAME}
    
    read -s -p "Harbor Password [${DEFAULT_HARBOR_PASSWORD}]: " harbor_password
    harbor_password=${harbor_password:-$DEFAULT_HARBOR_PASSWORD}
    log ""
    
    read -p "Harbor Project [${DEFAULT_HARBOR_PROJECT}]: " harbor_project
    harbor_project=${harbor_project:-$DEFAULT_HARBOR_PROJECT}
    
    log ""
    log "${BLUE}JFrog Artifactory Configuration:${NC}"
    read -p "Artifactory URL [${DEFAULT_ARTIFACTORY_URL}]: " artifactory_url
    artifactory_url=${artifactory_url:-$DEFAULT_ARTIFACTORY_URL}
    
    read -p "Artifactory Username [${DEFAULT_ARTIFACTORY_USERNAME}]: " artifactory_username
    artifactory_username=${artifactory_username:-$DEFAULT_ARTIFACTORY_USERNAME}
    
    read -s -p "Artifactory Password [${DEFAULT_ARTIFACTORY_PASSWORD}]: " artifactory_password
    artifactory_password=${artifactory_password:-$DEFAULT_ARTIFACTORY_PASSWORD}
    log ""
    
    # Generate custom template with user values
    log ""
    log "${BLUE}📝 Generating customized configuration...${NC}"
    
    cat > "github-secrets-custom.md" << EOF
# Custom GitHub Secrets Configuration

## Your Configuration Values:

### Harbor Settings:
\`\`\`
HARBOR_REGISTRY=${harbor_registry}
HARBOR_USERNAME=${harbor_username}
HARBOR_PASSWORD=${harbor_password}
HARBOR_PROJECT=${harbor_project}
\`\`\`

### JFrog Artifactory Settings:
\`\`\`
ARTIFACTORY_URL=${artifactory_url}
ARTIFACTORY_USERNAME=${artifactory_username}
ARTIFACTORY_PASSWORD=${artifactory_password}
\`\`\`

### Repository Settings (defaults):
\`\`\`
ARTIFACTORY_NUGET_REPO=${DEFAULT_NUGET_REPO}
ARTIFACTORY_PYPI_REPO=${DEFAULT_PYPI_REPO}
ARTIFACTORY_NPM_REPO=${DEFAULT_NPM_REPO}
ARTIFACTORY_GO_REPO=${DEFAULT_GO_REPO}
ARTIFACTORY_CARGO_REPO=${DEFAULT_CARGO_REPO}
ARTIFACTORY_GENERIC_REPO=${DEFAULT_GENERIC_REPO}
\`\`\`

## GitHub CLI Commands:
\`\`\`bash
gh secret set HARBOR_REGISTRY --body "${harbor_registry}"
gh secret set HARBOR_USERNAME --body "${harbor_username}"
gh secret set HARBOR_PASSWORD --body "${harbor_password}"
gh secret set HARBOR_PROJECT --body "${harbor_project}"
gh secret set ARTIFACTORY_URL --body "${artifactory_url}"
gh secret set ARTIFACTORY_USERNAME --body "${artifactory_username}"
gh secret set ARTIFACTORY_PASSWORD --body "${artifactory_password}"
gh secret set ARTIFACTORY_NUGET_REPO --body "${DEFAULT_NUGET_REPO}"
gh secret set ARTIFACTORY_PYPI_REPO --body "${DEFAULT_PYPI_REPO}"
gh secret set ARTIFACTORY_NPM_REPO --body "${DEFAULT_NPM_REPO}"
gh secret set ARTIFACTORY_GO_REPO --body "${DEFAULT_GO_REPO}"
gh secret set ARTIFACTORY_CARGO_REPO --body "${DEFAULT_CARGO_REPO}"
gh secret set ARTIFACTORY_GENERIC_REPO --body "${DEFAULT_GENERIC_REPO}"
\`\`\`
EOF

    log "${GREEN} Generated: github-secrets-custom.md${NC}"
    
    # Ask if they want to run GitHub CLI commands
    log ""
    read -p "Do you want to set these secrets using GitHub CLI now? (y/N): " use_gh_cli
    if [[ "$use_gh_cli" =~ ^[Yy]$ ]]; then
        setup_github_cli "$harbor_registry" "$harbor_username" "$harbor_password" "$harbor_project" \
                        "$artifactory_url" "$artifactory_username" "$artifactory_password"
    fi
}

# GitHub CLI setup
setup_github_cli() {
    local harbor_registry="$1"
    local harbor_username="$2"
    local harbor_password="$3"
    local harbor_project="$4"
    local artifactory_url="$5"
    local artifactory_username="$6"
    local artifactory_password="$7"
    
    log "${BLUE}Setting up secrets using GitHub CLI...${NC}"
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        log "${RED}GitHub CLI (gh) is not installed${NC}"
        log "${YELLOW}Install it from: https://cli.github.com/${NC}"
        return 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log "${RED}GitHub CLI is not authenticated${NC}"
        log "${YELLOW}Run: gh auth login${NC}"
        return 1
    fi
    
    log "${BLUE}Setting Harbor secrets...${NC}"
    gh secret set HARBOR_REGISTRY --body "${harbor_registry}" && log "${GREEN}  ✓ HARBOR_REGISTRY${NC}"
    gh secret set HARBOR_USERNAME --body "${harbor_username}" && log "${GREEN}  ✓ HARBOR_USERNAME${NC}"
    gh secret set HARBOR_PASSWORD --body "${harbor_password}" && log "${GREEN}  ✓ HARBOR_PASSWORD${NC}"
    gh secret set HARBOR_PROJECT --body "${harbor_project}" && log "${GREEN}  ✓ HARBOR_PROJECT${NC}"
    
    log "${BLUE}Setting Artifactory secrets...${NC}"
    gh secret set ARTIFACTORY_URL --body "${artifactory_url}" && log "${GREEN}  ✓ ARTIFACTORY_URL${NC}"
    gh secret set ARTIFACTORY_USERNAME --body "${artifactory_username}" && log "${GREEN}  ✓ ARTIFACTORY_USERNAME${NC}"
    gh secret set ARTIFACTORY_PASSWORD --body "${artifactory_password}" && log "${GREEN}  ✓ ARTIFACTORY_PASSWORD${NC}"
    
    log "${BLUE}Setting repository-specific secrets...${NC}"
    gh secret set ARTIFACTORY_NUGET_REPO --body "${DEFAULT_NUGET_REPO}" && log "${GREEN}  ✓ ARTIFACTORY_NUGET_REPO${NC}"
    gh secret set ARTIFACTORY_PYPI_REPO --body "${DEFAULT_PYPI_REPO}" && log "${GREEN}  ✓ ARTIFACTORY_PYPI_REPO${NC}"
    gh secret set ARTIFACTORY_NPM_REPO --body "${DEFAULT_NPM_REPO}" && log "${GREEN}  ✓ ARTIFACTORY_NPM_REPO${NC}"
    gh secret set ARTIFACTORY_GO_REPO --body "${DEFAULT_GO_REPO}" && log "${GREEN}  ✓ ARTIFACTORY_GO_REPO${NC}"
    gh secret set ARTIFACTORY_CARGO_REPO --body "${DEFAULT_CARGO_REPO}" && log "${GREEN}  ✓ ARTIFACTORY_CARGO_REPO${NC}"
    gh secret set ARTIFACTORY_GENERIC_REPO --body "${DEFAULT_GENERIC_REPO}" && log "${GREEN}  ✓ ARTIFACTORY_GENERIC_REPO${NC}"
    
    log ""
    log "${GREEN} All secrets configured successfully!${NC}"
    
    # List secrets to verify
    log "${BLUE}Configured secrets:${NC}"
    gh secret list
}

# Main function
main() {
    show_header
    
    case "${1:-}" in
        --interactive|-i)
            interactive_setup
            ;;
        --template|-t)
            generate_template
            ;;
        --github-cli|-g)
            if [[ -n "${2:-}" ]]; then
                gh repo set-current "$2"
            fi
            setup_github_cli "$DEFAULT_HARBOR_REGISTRY" "$DEFAULT_HARBOR_USERNAME" "$DEFAULT_HARBOR_PASSWORD" "$DEFAULT_HARBOR_PROJECT" \
                            "$DEFAULT_ARTIFACTORY_URL" "$DEFAULT_ARTIFACTORY_USERNAME" "$DEFAULT_ARTIFACTORY_PASSWORD"
            ;;
        --help|-h|"")
            show_usage
            ;;
        *)
            log "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Check arguments
if [[ "${1:-}" == "--repository" ]] || [[ "${1:-}" == "-r" ]]; then
    if [[ -n "${2:-}" ]]; then
        gh repo set-current "$2"
        shift 2
    else
        log "${RED}Repository argument required${NC}"
        show_usage
        exit 1
    fi
fi

# Run main function
main "$@"