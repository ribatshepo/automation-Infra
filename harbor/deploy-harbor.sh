#!/bin/bash

# Harbor Container Registry Deployment Script
# This script deploys Harbor container registry using Docker Compose

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Ansible is installed
check_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        error "Ansible is not installed or not in PATH"
        exit 1
    fi
}

# Check if inventory file exists
check_inventory() {
    if [[ ! -f ../inventory.yml ]]; then
        error "Inventory file not found. Please ensure ../inventory.yml exists."
        exit 1
    fi
}

# Function to run Harbor installation
install_harbor() {
    log "Starting Harbor installation..."
    
    if ansible-playbook -i ../inventory.yml install-harbor.yml "$@"; then
        success "Harbor installation completed successfully"
        return 0
    else
        error "Harbor installation failed"
        return 1
    fi
}

# Function to verify Harbor installation
verify_harbor() {
    log "Verifying Harbor installation..."
    
    if ansible-playbook -i ../inventory.yml verify-harbor.yml "$@"; then
        success "Harbor verification completed successfully"
        return 0
    else
        error "Harbor verification failed"
        return 1
    fi
}

# Function to manage Harbor services
manage_harbor() {
    local action=$1
    shift
    
    log "Managing Harbor services: $action"
    
    if ansible-playbook -i ../inventory.yml manage-harbor.yml -e "harbor_action=$action" "$@"; then
        success "Harbor service management ($action) completed successfully"
        return 0
    else
        error "Harbor service management ($action) failed"
        return 1
    fi
}

# Function to backup Harbor data
backup_harbor() {
    log "Starting Harbor backup..."
    
    if ansible-playbook -i ../inventory.yml backup-harbor.yml "$@"; then
        success "Harbor backup completed successfully"
        return 0
    else
        error "Harbor backup failed"
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Harbor Container Registry Deployment Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    install              Install Harbor container registry
    verify               Verify Harbor installation and health
    start                Start Harbor services
    stop                 Stop Harbor services
    restart              Restart Harbor services
    backup               Backup Harbor data and configuration
    help                 Show this help message

Options:
    --vault-pass         Prompt for vault password
    --check              Run in check mode (dry run)
    --verbose            Enable verbose output
    --force              Force operation without confirmation

Examples:
    $0 install --vault-pass --verbose
    $0 verify
    $0 restart --vault-pass
    $0 backup --vault-pass

EOF
}

# Main execution
main() {
    local command="${1:-help}"
    shift || true

    # Check prerequisites
    check_ansible
    check_inventory

    case "$command" in
        "install")
            install_harbor "$@"
            ;;
        "verify")
            verify_harbor "$@"
            ;;
        "start")
            manage_harbor "start" "$@"
            ;;
        "stop")
            manage_harbor "stop" "$@"
            ;;
        "restart")
            manage_harbor "restart" "$@"
            ;;
        "backup")
            backup_harbor "$@"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"