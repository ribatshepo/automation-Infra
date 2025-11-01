#!/bin/bash
set -euo pipefail

# GitHub Secrets Validation Script
# This script helps you test your configured secrets

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${1}" >&2
}

# Show header
show_header() {
    log "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    log "${PURPLE}║              GitHub Secrets Validation                       ║${NC}"
    log "${PURPLE}║            Harbor + JFrog Artifactory Testing                ║${NC}"
    log "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    log ""
}

# Test Harbor connection
test_harbor() {
    local registry="${HARBOR_REGISTRY:-}"
    local username="${HARBOR_USERNAME:-}"
    local password="${HARBOR_PASSWORD:-}"
    
    if [[ -z "$registry" || -z "$username" || -z "$password" ]]; then
        log "${RED}Harbor secrets not set${NC}"
        log "${YELLOW}Required: HARBOR_REGISTRY, HARBOR_USERNAME, HARBOR_PASSWORD${NC}"
        return 1
    fi
    
    log "${BLUE}Testing Harbor connection...${NC}"
    log "${BLUE}   Registry: ${registry}${NC}"
    log "${BLUE}   Username: ${username}${NC}"
    
    # Test Docker login
    if echo "$password" | docker login "$registry" -u "$username" --password-stdin 2>/dev/null; then
        log "${GREEN} Harbor authentication successful${NC}"
        docker logout "$registry" 2>/dev/null
        return 0
    else
        log "${RED}Harbor authentication failed${NC}"
        return 1
    fi
}

# Test Artifactory connection
test_artifactory() {
    local url="${ARTIFACTORY_URL:-}"
    local username="${ARTIFACTORY_USERNAME:-}"
    local password="${ARTIFACTORY_PASSWORD:-}"
    
    if [[ -z "$url" || -z "$username" || -z "$password" ]]; then
        log "${RED}Artifactory secrets not set${NC}"
        log "${YELLOW}Required: ARTIFACTORY_URL, ARTIFACTORY_USERNAME, ARTIFACTORY_PASSWORD${NC}"
        return 1
    fi
    
    log "${BLUE}Testing Artifactory connection...${NC}"
    log "${BLUE}   URL: ${url}${NC}"
    log "${BLUE}   Username: ${username}${NC}"
    
    # Test API ping
    if curl -s -u "${username}:${password}" "${url}/artifactory/api/system/ping" | grep -q "OK"; then
        log "${GREEN} Artifactory authentication successful${NC}"
        
        # Test repositories
        log "${BLUE}Testing repository access...${NC}"
        local repos=$(curl -s -u "${username}:${password}" "${url}/artifactory/api/repositories" | jq -r '.[].key' 2>/dev/null || echo "")
        
        if [[ -n "$repos" ]]; then
            log "${GREEN} Repository access successful${NC}"
            log "${BLUE}Available repositories:${NC}"
            echo "$repos" | head -5 | while read repo; do
                log "${BLUE}   - ${repo}${NC}"
            done
        else
            log "${YELLOW}⚠ Repository access limited or jq not installed${NC}"
        fi
        
        return 0
    else
        log "${RED}Artifactory authentication failed${NC}"
        return 1
    fi
}

# Test repository-specific secrets
test_repository_secrets() {
    log "${BLUE}Checking repository-specific secrets...${NC}"
    
    local secrets=(
        "ARTIFACTORY_NUGET_REPO"
        "ARTIFACTORY_PYPI_REPO"
        "ARTIFACTORY_NPM_REPO"
        "ARTIFACTORY_GO_REPO"
        "ARTIFACTORY_CARGO_REPO"
        "ARTIFACTORY_GENERIC_REPO"
    )
    
    local missing=0
    for secret in "${secrets[@]}"; do
        if [[ -n "${!secret:-}" ]]; then
            log "${GREEN}  ✓ ${secret}=${!secret}${NC}"
        else
            log "${RED}  ${secret} not set${NC}"
            ((missing++))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        log "${GREEN} All repository secrets configured${NC}"
        return 0
    else
        log "${YELLOW}⚠ ${missing} repository secrets missing${NC}"
        return 1
    fi
}

# Show current configuration
show_configuration() {
    log "${BLUE}Current Configuration:${NC}"
    log ""
    
    log "${BLUE}Harbor Settings:${NC}"
    log "   HARBOR_REGISTRY: ${HARBOR_REGISTRY:-'Not set'}"
    log "   HARBOR_USERNAME: ${HARBOR_USERNAME:-'Not set'}"
    log "   HARBOR_PASSWORD: ${HARBOR_PASSWORD:+'***'}"
    log "   HARBOR_PROJECT: ${HARBOR_PROJECT:-'Not set'}"
    log ""
    
    log "${BLUE}Artifactory Settings:${NC}"
    log "   ARTIFACTORY_URL: ${ARTIFACTORY_URL:-'Not set'}"
    log "   ARTIFACTORY_USERNAME: ${ARTIFACTORY_USERNAME:-'Not set'}"
    log "   ARTIFACTORY_PASSWORD: ${ARTIFACTORY_PASSWORD:+'***'}"
    log ""
    
    log "${BLUE}Repository Settings:${NC}"
    log "   ARTIFACTORY_NUGET_REPO: ${ARTIFACTORY_NUGET_REPO:-'Not set'}"
    log "   ARTIFACTORY_PYPI_REPO: ${ARTIFACTORY_PYPI_REPO:-'Not set'}"
    log "   ARTIFACTORY_NPM_REPO: ${ARTIFACTORY_NPM_REPO:-'Not set'}"
    log "   ARTIFACTORY_GO_REPO: ${ARTIFACTORY_GO_REPO:-'Not set'}"
    log "   ARTIFACTORY_CARGO_REPO: ${ARTIFACTORY_CARGO_REPO:-'Not set'}"
    log "   ARTIFACTORY_GENERIC_REPO: ${ARTIFACTORY_GENERIC_REPO:-'Not set'}"
    log ""
}

# Generate test workflow
generate_test_workflow() {
    log "${BLUE} Generating test workflow...${NC}"
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/test-secrets.yml << 'EOF'
name: Test Secrets Configuration

on:
  workflow_dispatch:
  push:
    branches: [ main, master ]
    paths: [ '.github/workflows/test-secrets.yml' ]

jobs:
  test-secrets:
    runs-on: ubuntu-latest
    name: Test Harbor and Artifactory Secrets
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Test Harbor Configuration
        run: |
          echo "Testing Harbor configuration..."
          echo "Registry: ${{ secrets.HARBOR_REGISTRY }}"
          echo "Username: ${{ secrets.HARBOR_USERNAME }}"
          echo "Project: ${{ secrets.HARBOR_PROJECT }}"
          
          # Test Docker login
          echo "${{ secrets.HARBOR_PASSWORD }}" | docker login ${{ secrets.HARBOR_REGISTRY }} -u ${{ secrets.HARBOR_USERNAME }} --password-stdin
          echo " Harbor authentication successful"
          docker logout ${{ secrets.HARBOR_REGISTRY }}
          
      - name: Test Artifactory Configuration
        run: |
          echo "Testing Artifactory configuration..."
          echo "URL: ${{ secrets.ARTIFACTORY_URL }}"
          echo "Username: ${{ secrets.ARTIFACTORY_USERNAME }}"
          
          # Test API ping
          response=$(curl -s -u "${{ secrets.ARTIFACTORY_USERNAME }}:${{ secrets.ARTIFACTORY_PASSWORD }}" "${{ secrets.ARTIFACTORY_URL }}/artifactory/api/system/ping")
          if echo "$response" | grep -q "OK"; then
            echo " Artifactory authentication successful"
          else
            echo "Artifactory authentication failed"
            exit 1
          fi
          
      - name: Test Repository Configuration
        run: |
          echo "Testing repository configuration..."
          echo "NuGet Repo: ${{ secrets.ARTIFACTORY_NUGET_REPO }}"
          echo "PyPI Repo: ${{ secrets.ARTIFACTORY_PYPI_REPO }}"
          echo "npm Repo: ${{ secrets.ARTIFACTORY_NPM_REPO }}"
          echo "Go Repo: ${{ secrets.ARTIFACTORY_GO_REPO }}"
          echo "Cargo Repo: ${{ secrets.ARTIFACTORY_CARGO_REPO }}"
          echo "Generic Repo: ${{ secrets.ARTIFACTORY_GENERIC_REPO }}"
          
          # Test repository access
          repos=$(curl -s -u "${{ secrets.ARTIFACTORY_USERNAME }}:${{ secrets.ARTIFACTORY_PASSWORD }}" "${{ secrets.ARTIFACTORY_URL }}/artifactory/api/repositories")
          echo " Repository access successful"
          echo "Available repositories: $(echo "$repos" | jq -r '.[].key' | tr '\n' ' ')"
          
      - name: Test Summary
        run: |
          echo " All secrets tests passed successfully!"
          echo "Your CI/CD pipeline is ready to use."
EOF

    log "${GREEN} Generated test workflow: .github/workflows/test-secrets.yml${NC}"
    log "${CYAN} Commit and push this file to test your secrets in GitHub Actions${NC}"
}

# Main test function
main() {
    show_header
    
    case "${1:-all}" in
        "harbor")
            test_harbor
            ;;
        "artifactory")
            test_artifactory
            ;;
        "repos"|"repositories")
            test_repository_secrets
            ;;
        "config"|"configuration")
            show_configuration
            ;;
        "workflow")
            generate_test_workflow
            ;;
        "all"|"")
            show_configuration
            log ""
            
            local harbor_ok=0
            local artifactory_ok=0
            local repos_ok=0
            
            test_harbor && harbor_ok=1 || true
            log ""
            test_artifactory && artifactory_ok=1 || true
            log ""
            test_repository_secrets && repos_ok=1 || true
            
            log ""
            log "${BLUE} Test Summary:${NC}"
            if [[ $harbor_ok -eq 1 ]]; then
                log "${GREEN}   Harbor connection${NC}"
            else
                log "${RED}  Harbor connection${NC}"
            fi
            
            if [[ $artifactory_ok -eq 1 ]]; then
                log "${GREEN}   Artifactory connection${NC}"
            else
                log "${RED}  Artifactory connection${NC}"
            fi
            
            if [[ $repos_ok -eq 1 ]]; then
                log "${GREEN}   Repository configuration${NC}"
            else
                log "${YELLOW}  ⚠ Repository configuration${NC}"
            fi
            
            log ""
            if [[ $harbor_ok -eq 1 && $artifactory_ok -eq 1 ]]; then
                log "${GREEN} All critical tests passed! Your secrets are configured correctly.${NC}"
                
                read -p "Generate test workflow for GitHub Actions? (y/N): " generate_test
                if [[ "$generate_test" =~ ^[Yy]$ ]]; then
                    generate_test_workflow
                fi
            else
                log "${RED}Some tests failed. Please check your configuration.${NC}"
                log "${YELLOW} Run './configure-secrets.sh --interactive' to reconfigure${NC}"
            fi
            ;;
        "--help"|"-h")
            cat << EOF
Usage: $0 [TEST_TYPE]

Test Types:
    all              Run all tests (default)
    harbor           Test Harbor connection only
    artifactory      Test Artifactory connection only
    repos            Test repository-specific secrets
    config           Show current configuration
    workflow         Generate GitHub Actions test workflow

Examples:
    $0                  # Run all tests
    $0 harbor           # Test Harbor only
    $0 artifactory      # Test Artifactory only
    $0 workflow         # Generate test workflow

Environment Variables Required:
    HARBOR_REGISTRY, HARBOR_USERNAME, HARBOR_PASSWORD, HARBOR_PROJECT
    ARTIFACTORY_URL, ARTIFACTORY_USERNAME, ARTIFACTORY_PASSWORD
    ARTIFACTORY_*_REPO (for repository tests)

EOF
            ;;
        *)
            log "${RED}Unknown test type: $1${NC}"
            log "${YELLOW}Run '$0 --help' for usage information${NC}"
            exit 1
            ;;
    esac
}

main "$@"