#!/bin/bash

# JFrog Artifactory Deployment Script
# Usage: ./deploy-artifactory.sh [install|verify|backup|manage]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_DIR="$SCRIPT_DIR"
INVENTORY_FILE="$SCRIPT_DIR/../inventory.yml"
VARS_FILE="$SCRIPT_DIR/vars.yml"
VAULT_FILE="$SCRIPT_DIR/vault.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check prerequisites
check_prerequisites() {
    log "${BLUE}Checking prerequisites...${NC}"
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        log "${RED}ERROR: Ansible is not installed${NC}"
        exit 1
    fi
    
    # Check if inventory file exists
    if [ ! -f "$INVENTORY_FILE" ]; then
        log "${RED}ERROR: Inventory file not found: $INVENTORY_FILE${NC}"
        exit 1
    fi
    
    # Check if vars file exists
    if [ ! -f "$VARS_FILE" ]; then
        log "${RED}ERROR: Variables file not found: $VARS_FILE${NC}"
        exit 1
    fi
    
    # Check if vault file exists
    if [ ! -f "$VAULT_FILE" ]; then
        log "${YELLOW}WARNING: Vault file not found: $VAULT_FILE${NC}"
        log "${YELLOW}Creating vault file from template...${NC}"
        cp "$VAULT_FILE.example" "$VAULT_FILE"
        log "${YELLOW}Please edit $VAULT_FILE and encrypt it with 'ansible-vault encrypt $VAULT_FILE'${NC}"
    fi
    
    log "${GREEN}Prerequisites check completed${NC}"
}

# Install Artifactory
install_artifactory() {
    log "${BLUE}Starting Artifactory installation...${NC}"
    
    ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_DIR/install-artifactory.yml" \
        --extra-vars "@$VARS_FILE" \
        --ask-vault-pass
    
    if [ $? -eq 0 ]; then
        log "${GREEN}Artifactory installation completed successfully!${NC}"
    else
        log "${RED}ERROR: Artifactory installation failed${NC}"
        exit 1
    fi
}

# Verify Artifactory installation
verify_artifactory() {
    log "${BLUE}Verifying Artifactory installation...${NC}"
    
    ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_DIR/verify-artifactory.yml" \
        --extra-vars "@$VARS_FILE"
    
    if [ $? -eq 0 ]; then
        log "${GREEN}Artifactory verification completed${NC}"
    else
        log "${RED}ERROR: Artifactory verification failed${NC}"
        exit 1
    fi
}

# Backup Artifactory
backup_artifactory() {
    log "${BLUE}Starting Artifactory backup...${NC}"
    
    ansible artifacts -i "$INVENTORY_FILE" -m shell \
        -a "/usr/local/bin/artifactory-backup.sh" \
        --become
    
    if [ $? -eq 0 ]; then
        log "${GREEN}Artifactory backup completed${NC}"
    else
        log "${RED}ERROR: Artifactory backup failed${NC}"
        exit 1
    fi
}

# Manage Artifactory
manage_artifactory() {
    log "${BLUE}Artifactory management options:${NC}"
    echo "1. Show admin credentials"
    echo "2. Test admin login"
    echo "3. Change admin password"
    echo "4. Show system information"
    echo "5. Restart service"
    echo "6. Stop service"
    echo "7. Start service"
    read -p "Choose an option (1-7): " choice
    
    case $choice in
        1)
            ansible artifacts -i "$INVENTORY_FILE" -m shell \
                -a "/usr/local/bin/artifactory-admin-password.sh --show"
            ;;
        2)
            ansible artifacts -i "$INVENTORY_FILE" -m shell \
                -a "/usr/local/bin/artifactory-admin-password.sh --test"
            ;;
        3)
            ansible artifacts -i "$INVENTORY_FILE" -m shell \
                -a "/usr/local/bin/artifactory-admin-password.sh --change"
            ;;
        4)
            ansible artifacts -i "$INVENTORY_FILE" -m shell \
                -a "/usr/local/bin/artifactory-admin-password.sh --info"
            ;;
        5)
            ansible artifacts -i "$INVENTORY_FILE" -m systemd \
                -a "name=artifactory state=restarted" --become
            ;;
        6)
            ansible artifacts -i "$INVENTORY_FILE" -m systemd \
                -a "name=artifactory state=stopped" --become
            ;;
        7)
            ansible artifacts -i "$INVENTORY_FILE" -m systemd \
                -a "name=artifactory state=started" --become
            ;;
        *)
            log "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
}

# Show usage
show_usage() {
    echo "JFrog Artifactory Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install    Install and configure JFrog Artifactory"
    echo "  verify     Verify Artifactory installation"
    echo "  backup     Create a backup of Artifactory"
    echo "  manage     Manage Artifactory (credentials, service, etc.)"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install    # Install Artifactory"
    echo "  $0 verify     # Verify installation"
    echo "  $0 backup     # Create backup"
    echo ""
}

# Main logic
case "$1" in
    install)
        check_prerequisites
        install_artifactory
        ;;
    verify)
        check_prerequisites
        verify_artifactory
        ;;
    backup)
        check_prerequisites
        backup_artifactory
        ;;
    manage)
        check_prerequisites
        manage_artifactory
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        log "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac