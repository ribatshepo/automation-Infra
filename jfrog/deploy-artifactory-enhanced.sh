#!/bin/bash
set -euo pipefail

# JFrog Artifactory Deployment Script - Enhanced Version
# Enhanced with automated troubleshooting and clean deployment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_FILE="${SCRIPT_DIR}/../inventory.yml"
VAULT_FILE="${SCRIPT_DIR}/vault.yml"
LOGFILE="${SCRIPT_DIR}/deployment.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${1}" | tee -a "${LOGFILE}"
}

# Check prerequisites
check_prerequisites() {
    log "${BLUE} Checking prerequisites...${NC}"
    
    if [[ ! -f "${INVENTORY_FILE}" ]]; then
        log "${RED} Inventory file not found: ${INVENTORY_FILE}${NC}"
        exit 1
    fi
    
    if [[ ! -f "${VAULT_FILE}" ]]; then
        log "${RED} Vault file not found: ${VAULT_FILE}${NC}"
        exit 1
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        log "${RED} ansible-playbook not found${NC}"
        exit 1
    fi
    
    log "${GREEN}Prerequisites check passed${NC}"
}

# Clean deployment function
clean_deploy() {
    log "${YELLOW}🧹 Starting clean deployment...${NC}"
    
    log "${BLUE} Step 1: Stopping existing services...${NC}"
    ansible nexus-1 -i "${INVENTORY_FILE}" -m systemd -a "name=artifactory state=stopped" --ask-vault-pass --become || true
    
    log "${BLUE} Step 2: Cleaning old installations...${NC}"
    ansible nexus-1 -i "${INVENTORY_FILE}" -m shell -a "rm -rf /opt/jfrog/artifactory /var/opt/jfrog/artifactory /etc/opt/jfrog/artifactory" --ask-vault-pass --become || true
    
    log "${BLUE} Step 3: Starting fresh installation...${NC}"
    install_artifactory
}

# Main installation function
install_artifactory() {
    log "${BLUE}Starting JFrog Artifactory installation...${NC}"
    
    if ansible-playbook -i "${INVENTORY_FILE}" install-artifactory.yml --ask-vault-pass --check; then
        log "${GREEN}Playbook syntax check passed${NC}"
    else
        log "${RED} Playbook syntax check failed${NC}"
        exit 1
    fi
    
    # Run the installation
    if ansible-playbook -i "${INVENTORY_FILE}" install-artifactory.yml --ask-vault-pass; then
        log "${GREEN} Installation completed successfully!${NC}"
        show_access_info
    else
        log "${RED} Installation failed${NC}"
        log "${YELLOW}Try running with 'clean' command for a fresh installation${NC}"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    log "${BLUE} Verifying deployment...${NC}"
    
    ansible-playbook -i "${INVENTORY_FILE}" verify-artifactory.yml --ask-vault-pass || {
        log "${YELLOW}  Verification had issues. Check the output above.${NC}"
    }
}

# Show access information
show_access_info() {
    log "${GREEN}📍 Access Information:${NC}"
    
    # Get the host IP
    HOST_IP=$(ansible nexus-1 -i "${INVENTORY_FILE}" -m setup -a "filter=ansible_default_ipv4" --ask-vault-pass | grep -o '"address": "[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "10.100.10.215")
    
    log "${BLUE} Web UI: http://${HOST_IP}:8081/ui/${NC}"
    log "${BLUE} Username: admin${NC}"
    log "${BLUE} Password: Check vault.yml (vault_artifactory_admin_password)${NC}"
    log "${BLUE} API: http://${HOST_IP}:8081/artifactory/api/${NC}"
}

# Backup function
backup_artifactory() {
    log "${BLUE} Creating backup...${NC}"
    
    ansible-playbook -i "${INVENTORY_FILE}" backup-artifactory.yml --ask-vault-pass
}

# Manage services
manage_service() {
    local action=$1
    log "${BLUE}${action^}ing Artifactory service...${NC}"
    
    ansible nexus-1 -i "${INVENTORY_FILE}" -m systemd -a "name=artifactory state=${action}" --ask-vault-pass --become
    
    if [[ "${action}" == "start" ]] || [[ "${action}" == "restart" ]]; then
        log "${YELLOW}⏳ Waiting for service to be ready...${NC}"
        sleep 30
        verify_deployment
    fi
}

# Troubleshoot function
troubleshoot() {
    log "${YELLOW}Running troubleshooting diagnostics...${NC}"
    
    log "${BLUE} System Information:${NC}"
    ansible nexus-1 -i "${INVENTORY_FILE}" -m shell -a "
        echo '=== System Info ===' && \
        uname -a && \
        echo '=== Memory ===' && \
        free -h && \
        echo '=== Disk Space ===' && \
        df -h && \
        echo '=== Java Version ===' && \
        java -version 2>&1 && \
        echo '=== Service Status ===' && \
        systemctl status artifactory.service || true && \
        echo '=== Port Status ===' && \
        ss -tlnp | grep :8081 || echo 'Port 8081 not listening' && \
        echo '=== Recent Logs ===' && \
        journalctl -u artifactory.service --no-pager -n 20 || true
    " --ask-vault-pass --become
}

# Show help
show_help() {
    cat << EOF
JFrog Artifactory Deployment Script - Enhanced Version

Usage: $0 [COMMAND]

Commands:
    install         Install JFrog Artifactory (default)
    clean           Clean installation (removes existing installation)
    verify          Verify current deployment
    backup          Create backup of Artifactory
    start           Start Artifactory service
    stop            Stop Artifactory service  
    restart         Restart Artifactory service
    troubleshoot    Run diagnostic checks
    help            Show this help message

Examples:
    $0                      # Install with existing data
    $0 clean               # Clean installation
    $0 verify              # Verify deployment
    $0 troubleshoot        # Diagnose issues

EOF
}

# Main script logic
main() {
    # Initialize log file
    echo "JFrog Artifactory Deployment Log - $(date)" > "${LOGFILE}"
    
    check_prerequisites
    
    case "${1:-install}" in
        "install")
            install_artifactory
            ;;
        "clean")
            clean_deploy
            ;;
        "verify")
            verify_deployment
            ;;
        "backup")
            backup_artifactory
            ;;
        "start")
            manage_service "start"
            ;;
        "stop")
            manage_service "stop"
            ;;
        "restart")
            manage_service "restart"
            ;;
        "troubleshoot")
            troubleshoot
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log "${RED} Unknown command: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"