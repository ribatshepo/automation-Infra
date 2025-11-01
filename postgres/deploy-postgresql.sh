#!/bin/bash

# PostgreSQL Deployment Script
# This script deploys PostgreSQL database server to the infrastructure

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
        error "Ansible is not installed. Please install Ansible first."
        echo "To install Ansible:"
        echo "  Ubuntu/Debian: sudo apt update && sudo apt install ansible"
        echo "  RHEL/CentOS: sudo yum install ansible"
        echo "  macOS: brew install ansible"
        exit 1
    fi
    success "Ansible is installed: $(ansible --version | head -n1)"
}

# Test SSH connectivity to database hosts
test_connectivity() {
    log "Testing SSH connectivity to database hosts..."
    
    if ansible databases -m ping -i ../inventory.yml; then
        success "Database hosts are reachable via SSH"
    else
        error "Database hosts are not reachable. Please check:"
        echo "  1. SSH keys are properly configured"
        echo "  2. Database VMs are running"
        echo "  3. Network connectivity"
        echo "  4. IP addresses in ../inventory.yml are correct"
        exit 1
    fi
}

# Check for required variables
check_variables() {
    log "Checking for required variables..."
    
    # Check if password variables are set (can be in vault or environment)
    if ! ansible databases -m debug -a "var=postgresql_app_password" -i ../inventory.yml --check > /dev/null 2>&1; then
        warning "postgresql_app_password not set. Using default password."
        echo "Consider setting secure passwords using:"
        echo "  1. Ansible Vault: ansible-vault create group_vars/databases/vault.yml"
        echo "  2. Environment variables: export postgresql_app_password='your_secure_password'"
    fi
    
    success "Variable check completed"
}

# Deploy PostgreSQL
deploy_postgresql() {
    log "Starting PostgreSQL deployment..."
    
    # Run the main playbook
    if ansible-playbook -i ../inventory.yml install-postgresql.yml --ask-become-pass; then
        success "PostgreSQL deployed successfully"
    else
        error "PostgreSQL deployment failed"
        exit 1
    fi
}

# Deploy PostgreSQL with vault
deploy_postgresql_vault() {
    log "Starting PostgreSQL deployment with Ansible Vault..."
    
    # Run the main playbook with vault
    if ansible-playbook -i ../inventory.yml install-postgresql.yml --ask-become-pass --ask-vault-pass; then
        success "PostgreSQL deployed successfully"
    else
        error "PostgreSQL deployment failed"
        exit 1
    fi
}

# Verify installation
verify_installation() {
    log "Verifying PostgreSQL installation..."
    
    if ansible-playbook -i ../inventory.yml verify-postgresql.yml; then
        success "PostgreSQL verification completed"
    else
        warning "Some verification checks failed. Check the output above."
    fi
}

# Create database backup
create_backup() {
    log "Creating database backup..."
    
    if ansible databases -m command -a "/usr/local/bin/postgresql-backup.sh" -i ../inventory.yml --become; then
        success "Database backup created successfully"
    else
        warning "Backup creation failed or script not found"
    fi
}

# Show database status
show_status() {
    log "Checking PostgreSQL status..."
    
    ansible databases -m systemd -a "name=postgresql" -i ../inventory.yml --become
    ansible databases -m command -a "sudo -u postgres psql -c 'SELECT version();'" -i ../inventory.yml
}

# Display security recommendations
show_security_recommendations() {
    log "Security Recommendations:"
    echo "======================================"
    echo "1. Change default passwords:"
    echo "   - Set postgresql_app_password in vault or environment"
    echo "   - Set postgresql_readonly_password in vault or environment"
    echo ""
    echo "2. Configure SSL certificates:"
    echo "   - Replace self-signed certificates with proper SSL certs"
    echo "   - Update postgresql.conf SSL settings"
    echo ""
    echo "3. Firewall configuration:"
    echo "   - Ensure only necessary hosts can access port 5432"
    echo "   - Consider using connection pooling (PgBouncer)"
    echo ""
    echo "4. Regular maintenance:"
    echo "   - Monitor backup jobs"
    echo "   - Review PostgreSQL logs regularly"
    echo "   - Update PostgreSQL version periodically"
    echo "======================================"
}

# Display summary
show_summary() {
    log "Deployment Summary:"
    echo "======================================"
    echo "✓ PostgreSQL 15 installed"
    echo "✓ Database server configured and tuned"
    echo "✓ Application databases created:"
    echo "  - app_production"
    echo "  - app_staging"
    echo "✓ Users configured:"
    echo "  - app_user (read/write access)"
    echo "  - readonly_user (read-only access)"
    echo "✓ Security configured (pg_hba.conf)"
    echo "✓ Performance tuning applied"
    echo "✓ Backup system configured"
    echo "✓ Extensions installed (uuid-ossp, pgcrypto, unaccent)"
    echo ""
    echo "Connection details:"
    echo "  Host: 10.100.10.220"
    echo "  Port: 5432"
    echo "  Databases: app_production, app_staging"
    echo ""
    echo "Next steps:"
    echo "1. Set secure passwords using Ansible Vault"
    echo "2. Configure application connection strings"
    echo "3. Set up monitoring (consider pg_stat_statements)"
    echo "4. Configure SSL certificates for production"
    echo "======================================"
}

# Main execution
main() {
    log "Starting PostgreSQL deployment for Proxmox infrastructure"
    
    # Check prerequisites
    check_ansible
    
    # Test connectivity
    test_connectivity
    
    # Check variables
    check_variables
    
    # Deploy PostgreSQL
    deploy_postgresql
    
    # Verify installation
    verify_installation
    
    # Show summary
    show_summary
    
    # Show security recommendations
    show_security_recommendations
    
    success "PostgreSQL deployment completed successfully!"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "deploy-vault")
        log "Running deployment with Ansible Vault..."
        check_ansible
        test_connectivity
        deploy_postgresql_vault
        verify_installation
        show_summary
        ;;
    "verify")
        log "Running verification only..."
        verify_installation
        ;;
    "test")
        log "Testing connectivity only..."
        test_connectivity
        ;;
    "status")
        log "Checking PostgreSQL status..."
        show_status
        ;;
    "backup")
        log "Creating database backup..."
        create_backup
        ;;
    "security")
        log "Showing security recommendations..."
        show_security_recommendations
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [deploy|deploy-vault|verify|test|status|backup|security|help]"
        echo ""
        echo "Commands:"
        echo "  deploy       - Full deployment (default)"
        echo "  deploy-vault - Deploy with Ansible Vault for passwords"
        echo "  verify       - Verify existing installation"
        echo "  test         - Test SSH connectivity only"
        echo "  status       - Check PostgreSQL service status"
        echo "  backup       - Create database backup"
        echo "  security     - Show security recommendations"
        echo "  help         - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  postgresql_app_password      - Password for app_user"
        echo "  postgresql_readonly_password - Password for readonly_user"
        ;;
    *)
        error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac