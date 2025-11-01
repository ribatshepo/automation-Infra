#!/bin/bash
# MinIO Deployment Script
# Automates the deployment of MinIO Object Storage

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.yml"
PLAYBOOK_DIR="$SCRIPT_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage information
show_usage() {
    cat << EOF
MinIO Deployment Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    install           Install and configure MinIO
    verify            Verify MinIO installation
    backup            Run MinIO backup
    health-check      Run MinIO health check
    create-vault      Create encrypted vault file
    full-deploy       Complete deployment (install + verify)
    help              Show this help message

Options:
    --vault-pass      Prompt for vault password
    --check           Run in check mode (dry run)
    --verbose         Enable verbose output
    --force           Force operation without confirmation

Examples:
    $0 install --vault-pass
    $0 verify
    $0 full-deploy --vault-pass --verbose
    $0 backup
    $0 create-vault

EOF
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Check if inventory file exists
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        log_error "Inventory file not found: $INVENTORY_FILE"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "$PLAYBOOK_DIR/install-minio.yml" ]]; then
        log_error "MinIO playbooks not found. Make sure you're in the correct directory."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create vault file
create_vault() {
    local vault_file="$PLAYBOOK_DIR/vault.yml"
    local vault_example="$PLAYBOOK_DIR/vault.yml.example"
    
    log_info "Creating vault file..."
    
    if [[ -f "$vault_file" ]]; then
        log_warning "Vault file already exists: $vault_file"
        if [[ "$FORCE_MODE" != "true" ]]; then
            read -p "Do you want to overwrite it? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Vault creation cancelled"
                return 0
            fi
        fi
    fi
    
    if [[ ! -f "$vault_example" ]]; then
        log_error "Vault example file not found: $vault_example"
        exit 1
    fi
    
    # Copy example to vault file
    cp "$vault_example" "$vault_file"
    
    # Generate random passwords
    log_info "Generating secure passwords..."
    
    local admin_password=$(openssl rand -base64 32)
    local app_password=$(openssl rand -base64 32)
    local readonly_password=$(openssl rand -base64 32)
    local backup_password=$(openssl rand -base64 32)
    local jwt_secret=$(openssl rand -base64 64)
    local webhook_secret=$(openssl rand -base64 32)
    local service_access_key=$(openssl rand -hex 16)
    local service_secret_key=$(openssl rand -base64 32)
    
    # Replace placeholders with generated passwords
    sed -i "s/your-strong-admin-password-here/$admin_password/g" "$vault_file"
    sed -i "s/your-strong-app-password-here/$app_password/g" "$vault_file"
    sed -i "s/your-strong-readonly-password-here/$readonly_password/g" "$vault_file"
    sed -i "s/your-strong-backup-password-here/$backup_password/g" "$vault_file"
    sed -i "s/your-jwt-secret-key-here/$jwt_secret/g" "$vault_file"
    sed -i "s/your-webhook-secret-here/$webhook_secret/g" "$vault_file"
    sed -i "s/service-access-key/$service_access_key/g" "$vault_file"
    sed -i "s/service-secret-key/$service_secret_key/g" "$vault_file"
    sed -i "s/your-db-password-here/$(openssl rand -base64 32)/g" "$vault_file"
    
    # Encrypt the vault file
    log_info "Encrypting vault file..."
    ansible-vault encrypt "$vault_file"
    
    log_success "Vault file created and encrypted: $vault_file"
    log_info "Generated credentials:"
    echo "  - MinIO Root User: admin"
    echo "  - MinIO Root Password: $admin_password"
    echo "  - App User Password: $app_password"
    echo "  - Service Access Key: $service_access_key"
    log_warning "Save these credentials securely!"
}

# Install MinIO
install_minio() {
    log_info "Starting MinIO installation..."
    
    local ansible_opts=""
    
    if [[ "$VAULT_PASS" == "true" ]]; then
        ansible_opts="$ansible_opts --ask-vault-pass"
    fi
    
    if [[ "$CHECK_MODE" == "true" ]]; then
        ansible_opts="$ansible_opts --check"
        log_info "Running in check mode (dry run)"
    fi
    
    if [[ "$VERBOSE_MODE" == "true" ]]; then
        ansible_opts="$ansible_opts -v"
    fi
    
    # Run the installation playbook
    cd "$PLAYBOOK_DIR"
    if ansible-playbook -i "$INVENTORY_FILE" install-minio.yml $ansible_opts; then
        log_success "MinIO installation completed successfully"
    else
        log_error "MinIO installation failed"
        exit 1
    fi
}

# Verify MinIO installation
verify_minio() {
    log_info "Verifying MinIO installation..."
    
    local ansible_opts=""
    
    if [[ "$VAULT_PASS" == "true" ]]; then
        ansible_opts="$ansible_opts --ask-vault-pass"
    fi
    
    if [[ "$VERBOSE_MODE" == "true" ]]; then
        ansible_opts="$ansible_opts -v"
    fi
    
    # Run the verification playbook
    cd "$PLAYBOOK_DIR"
    if ansible-playbook -i "$INVENTORY_FILE" verify-minio.yml $ansible_opts; then
        log_success "MinIO verification completed successfully"
    else
        log_error "MinIO verification failed"
        exit 1
    fi
}

# Run MinIO backup
run_backup() {
    log_info "Running MinIO backup..."
    
    # Run backup on the MinIO server
    if ansible storage -i "$INVENTORY_FILE" -m shell -a "/usr/local/bin/minio-backup.sh" -b; then
        log_success "MinIO backup completed successfully"
    else
        log_error "MinIO backup failed"
        exit 1
    fi
}

# Run MinIO health check
run_health_check() {
    log_info "Running MinIO health check..."
    
    # Run health check on the MinIO server
    if ansible storage -i "$INVENTORY_FILE" -m shell -a "/usr/local/bin/minio-health-check.sh" -b; then
        log_success "MinIO health check completed successfully"
    else
        log_warning "MinIO health check reported issues"
        exit 1
    fi
}

# Full deployment (install + verify)
full_deploy() {
    log_info "Starting full MinIO deployment..."
    
    install_minio
    log_info "Waiting for MinIO to stabilize..."
    sleep 30
    verify_minio
    
    log_success "Full MinIO deployment completed successfully"
    
    # Display deployment summary
    log_info "Deployment Summary:"
    echo "==================="
    echo "MinIO has been successfully deployed and verified."
    echo "Access URLs (replace <IP> with your server IP):"
    echo "- MinIO Server: http://<IP>:9000"
    echo "- MinIO Console: http://<IP>:9001"
    echo ""
    echo "Default Buckets Created:"
    echo "- data (private)"
    echo "- backups (private)"
    echo "- logs (private)"
    echo "- uploads (public-read)"
    echo ""
    echo "Backup is scheduled daily at 3:00 AM"
    echo "Health checks are available via /usr/local/bin/minio-health-check.sh"
}

# Main function
main() {
    local command=""
    
    # Default options
    VAULT_PASS="false"
    CHECK_MODE="false"
    VERBOSE_MODE="false"
    FORCE_MODE="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            install|verify|backup|health-check|create-vault|full-deploy|help)
                command="$1"
                shift
                ;;
            --vault-pass)
                VAULT_PASS="true"
                shift
                ;;
            --check)
                CHECK_MODE="true"
                shift
                ;;
            --verbose)
                VERBOSE_MODE="true"
                shift
                ;;
            --force)
                FORCE_MODE="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Show usage if no command provided
    if [[ -z "$command" ]]; then
        show_usage
        exit 1
    fi
    
    # Check prerequisites (except for help)
    if [[ "$command" != "help" ]]; then
        check_prerequisites
    fi
    
    # Execute command
    case "$command" in
        install)
            install_minio
            ;;
        verify)
            verify_minio
            ;;
        backup)
            run_backup
            ;;
        health-check)
            run_health_check
            ;;
        create-vault)
            create_vault
            ;;
        full-deploy)
            full_deploy
            ;;
        help)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"