#!/bin/bash

# QEMU Guest Agent Deployment Script
# This script deploys qemu-guest-agent to all VMs in the infrastructure

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

# Test SSH connectivity to all hosts
test_connectivity() {
    log "Testing SSH connectivity to all hosts..."
    
    if ansible all -m ping -i ../inventory.yml; then
        success "All hosts are reachable via SSH"
    else
        error "Some hosts are not reachable. Please check:"
        echo "  1. SSH keys are properly configured"
        echo "  2. All VMs are running"
        echo "  3. Network connectivity"
        echo "  4. IP addresses in ../inventory.yml are correct"
        exit 1
    fi
}

# Deploy qemu-guest-agent
deploy_qemu_guest_agent() {
    log "Starting QEMU Guest Agent deployment..."
    
    # Run the main playbook
    if ansible-playbook -i ../inventory.yml install-qemu-guest-agent.yml; then
        success "QEMU Guest Agent deployed successfully"
    else
        error "QEMU Guest Agent deployment failed"
        exit 1
    fi
}

# Verify installation
verify_installation() {
    log "Verifying QEMU Guest Agent installation..."
    
    if ansible-playbook -i ../inventory.yml verify-qemu-guest-agent.yml; then
        success "QEMU Guest Agent verification completed"
    else
        warning "Some verification checks failed. Check the output above."
    fi
}

# Display summary
show_summary() {
    log "Deployment Summary:"
    echo "======================================"
    echo "✓ QEMU Guest Agent installed on all VMs"
    echo "✓ Service enabled and started"
    echo "✓ Configuration files created"
    echo "✓ fsfreeze hooks configured for database VMs"
    echo ""
    echo "Next steps:"
    echo "1. Verify in Proxmox that guest agent is detected"
    echo "2. Test snapshot functionality"
    echo "3. Configure backup schedules"
    echo "======================================"
}

# Main execution
main() {
    log "Starting QEMU Guest Agent deployment for Proxmox infrastructure"
    
    # Check prerequisites
    check_ansible
    
    # Test connectivity
    test_connectivity
    
    # Deploy qemu-guest-agent
    deploy_qemu_guest_agent
    
    # Verify installation
    verify_installation
    
    # Show summary
    show_summary
    
    success "QEMU Guest Agent deployment completed successfully!"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "verify")
        log "Running verification only..."
        verify_installation
        ;;
    "test")
        log "Testing connectivity only..."
        test_connectivity
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [deploy|verify|test|help]"
        echo ""
        echo "Commands:"
        echo "  deploy  - Full deployment (default)"
        echo "  verify  - Verify existing installation"
        echo "  test    - Test SSH connectivity only"
        echo "  help    - Show this help message"
        ;;
    *)
        error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac