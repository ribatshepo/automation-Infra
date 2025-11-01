#!/bin/bash
# Redis Deployment Script
# Usage: ./deploy-redis.sh [redis|redis-stack] [deploy-vault|deploy-no-vault]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INVENTORY_FILE="$PROJECT_ROOT/inventory.yml"
ANSIBLE_CONFIG="$PROJECT_ROOT/ansible.cfg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="$SCRIPT_DIR/deployment.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Functions
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        error "Ansible is not installed. Please install Ansible first."
    fi
    
    local ansible_version=$(ansible --version | head -n1)
    success "Ansible is installed: $ansible_version"
    
    # Check if inventory file exists
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        error "Inventory file not found: $INVENTORY_FILE"
    fi
    
    # Check if ansible.cfg exists
    if [[ ! -f "$ANSIBLE_CONFIG" ]]; then
        warning "Ansible config not found: $ANSIBLE_CONFIG"
    fi
    
    # Test SSH connectivity
    log "Testing SSH connectivity to Redis hosts..."
    if ansible redis -i "$INVENTORY_FILE" -m ping &> /dev/null; then
        success "Redis hosts are reachable via SSH"
    else
        error "Cannot reach Redis hosts via SSH. Check your inventory and SSH keys."
    fi
}

deploy_redis() {
    local service_type="$1"
    local vault_mode="$2"
    
    log "Starting Redis deployment..."
    log "Service Type: $service_type"
    log "Vault Mode: $vault_mode"
    
    # Determine playbook based on service type
    local playbook
    case "$service_type" in
        "redis")
            playbook="install-redis.yml"
            ;;
        "redis-stack")
            playbook="install-redis-stack.yml"
            ;;
        *)
            error "Invalid service type: $service_type. Use 'redis' or 'redis-stack'"
            ;;
    esac
    
    # Build ansible-playbook command
    local ansible_cmd="ansible-playbook -i $INVENTORY_FILE $playbook"
    
    # Add vault options if needed
    if [[ "$vault_mode" == "deploy-vault" ]]; then
        if [[ ! -f "$SCRIPT_DIR/vault.yml" ]]; then
            error "Vault file not found: $SCRIPT_DIR/vault.yml. Create it from vault.yml.example"
        fi
        ansible_cmd="$ansible_cmd --ask-vault-pass"
    fi
    
    # Always ask for become password
    ansible_cmd="$ansible_cmd --ask-become-pass"
    
    # Execute deployment
    log "Executing: $ansible_cmd"
    
    cd "$SCRIPT_DIR"
    if eval "$ansible_cmd"; then
        success "$service_type deployed successfully"
    else
        error "$service_type deployment failed"
    fi
}

verify_deployment() {
    local vault_mode="$1"
    
    log "Verifying Redis installation..."
    
    local ansible_cmd="ansible-playbook -i $INVENTORY_FILE verify-redis.yml"
    
    if [[ "$vault_mode" == "deploy-vault" ]]; then
        ansible_cmd="$ansible_cmd --ask-vault-pass"
    fi
    
    ansible_cmd="$ansible_cmd --ask-become-pass"
    
    cd "$SCRIPT_DIR"
    if eval "$ansible_cmd"; then
        success "Redis verification completed successfully"
        return 0
    else
        warning "Some verification checks failed. Check the output above."
        return 1
    fi
}

create_vault_file() {
    if [[ ! -f "$SCRIPT_DIR/vault.yml" ]] && [[ -f "$SCRIPT_DIR/vault.yml.example" ]]; then
        info "Creating vault.yml from example..."
        cp "$SCRIPT_DIR/vault.yml.example" "$SCRIPT_DIR/vault.yml"
        warning "Please edit vault.yml with your passwords before running deployment with vault!"
        warning "Then encrypt it with: ansible-vault encrypt vault.yml"
        exit 1
    fi
}

print_usage() {
    cat << EOF
Redis Deployment Script

Usage: $0 [SERVICE_TYPE] [VAULT_MODE]

SERVICE_TYPE:
    redis       - Deploy standard Redis server
    redis-stack - Deploy Redis Stack with modules (RedisJSON, RediSearch, etc.)

VAULT_MODE:
    deploy-vault    - Deploy with Ansible Vault (requires vault.yml)
    deploy-no-vault - Deploy without Ansible Vault (development only)

Examples:
    $0 redis deploy-vault           # Deploy Redis with encrypted passwords
    $0 redis-stack deploy-vault     # Deploy Redis Stack with encrypted passwords
    $0 redis deploy-no-vault        # Deploy Redis without vault (dev only)

Prerequisites:
    - Ansible installed
    - SSH access to target hosts
    - Inventory file configured
    - vault.yml file (for vault deployments)

Files:
    - inventory.yml: Ansible inventory with Redis hosts
    - vars.yml: Configuration variables
    - vault.yml: Encrypted passwords (create from vault.yml.example)
EOF
}

print_deployment_summary() {
    local service_type="$1"
    
    cat << EOF

======================================
Redis Deployment Summary
======================================
$(if [[ "$service_type" == "redis-stack" ]]; then echo "✓ Redis Stack installed with modules:"; else echo "✓ Redis server installed"; fi)
$(if [[ "$service_type" == "redis-stack" ]]; then echo "  - RedisJSON (JSON data type)"; fi)
$(if [[ "$service_type" == "redis-stack" ]]; then echo "  - RediSearch (Full-text search)"; fi)
$(if [[ "$service_type" == "redis-stack" ]]; then echo "  - RedisGraph (Graph database)"; fi)
$(if [[ "$service_type" == "redis-stack" ]]; then echo "  - RedisTimeSeries (Time series data)"; fi)
$(if [[ "$service_type" == "redis-stack" ]]; then echo "  - RedisBloom (Probabilistic data structures)"; fi)
✓ Security configured with authentication
✓ Performance tuning applied
✓ Backup system configured
✓ Log rotation configured
✓ Service monitoring enabled

Connection details:
  Host: $(grep -A5 '\[redis\]' "$INVENTORY_FILE" | grep -E '^[0-9]' | head -1 | awk '{print $1}' || echo "Check inventory.yml")
  Port: 6379
  Authentication: Enabled (use configured users)

Next steps:
1. Test connection: redis-cli -h <host> -p 6379 -a <password> ping
2. Configure application connection strings
3. Set up monitoring and alerting
4. Review backup schedule
======================================
EOF
}

main() {
    # Parse arguments
    local service_type="${1:-}"
    local vault_mode="${2:-}"
    
    # Show usage if no arguments
    if [[ -z "$service_type" ]] || [[ -z "$vault_mode" ]]; then
        print_usage
        exit 1
    fi
    
    # Validate arguments
    if [[ "$service_type" != "redis" ]] && [[ "$service_type" != "redis-stack" ]]; then
        error "Invalid service type. Use 'redis' or 'redis-stack'"
    fi
    
    if [[ "$vault_mode" != "deploy-vault" ]] && [[ "$vault_mode" != "deploy-no-vault" ]]; then
        error "Invalid vault mode. Use 'deploy-vault' or 'deploy-no-vault'"
    fi
    
    # Check for vault file if using vault
    if [[ "$vault_mode" == "deploy-vault" ]]; then
        create_vault_file
    fi
    
    log "Redis Deployment Starting..."
    log "Service Type: $service_type"
    log "Vault Mode: $vault_mode"
    
    # Run deployment steps
    check_prerequisites
    deploy_redis "$service_type" "$vault_mode"
    
    if verify_deployment "$vault_mode"; then
        print_deployment_summary "$service_type"
    else
        warning "Deployment completed but some verification checks failed."
    fi
    
    log "Redis deployment process completed."
}

# Run main function with all arguments
main "$@"