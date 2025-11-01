#!/bin/bash
# Kubernetes Cluster Deployment Script
# Deploys a production-ready Kubernetes cluster with HAProxy load balancer

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
PURPLE='\033[0;35m'
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

log_stage() {
    echo -e "${PURPLE}[STAGE]${NC} $1"
}

# Show usage information
show_usage() {
    cat << EOF
Kubernetes Cluster Deployment Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    stage1               Run Stage 1: Setup HAProxy and prepare nodes
    stage2               Run Stage 2: Initialize cluster and join nodes
    stage3               Run Stage 3: Install essential services
    full-deploy          Complete deployment (all stages)
    verify               Verify cluster health
    create-vault         Create encrypted vault file
    get-kubeconfig       Download kubeconfig file
    get-dashboard-token  Get Kubernetes Dashboard token
    destroy              Destroy the cluster (DANGEROUS)
    help                 Show this help message

Stage 1 Components:
    haproxy              Setup HAProxy load balancer
    prepare-nodes        Prepare all nodes for Kubernetes

Stage 2 Components:
    init-master          Initialize first master node
    join-masters         Join additional master nodes
    join-workers         Join worker nodes
    verify-cluster       Verify cluster health

Stage 3 Components:
    install-essentials   Install metrics server, dashboard, ingress

Options:
    --vault-pass         Prompt for vault password
    --check              Run in check mode (dry run)
    --verbose            Enable verbose output
    --force              Force operation without confirmation
    --skip-verify        Skip verification steps

Examples:
    $0 full-deploy --vault-pass --verbose
    $0 stage1 --vault-pass
    $0 stage2
    $0 verify
    $0 get-dashboard-token

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
    if [[ ! -f "$PLAYBOOK_DIR/vars.yml" ]]; then
        log_error "Kubernetes configuration not found. Make sure you're in the correct directory."
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
    
    local haproxy_pass=$(openssl rand -base64 32 | tr -d '/+' | head -c 24)
    local admin_pass=$(openssl rand -base64 32 | tr -d '/+' | head -c 24)
    local bootstrap_token=$(printf "%06x.%016x" $((RANDOM*RANDOM)) $((RANDOM*RANDOM*RANDOM*RANDOM)))
    local ca_passphrase=$(openssl rand -base64 32 | tr -d '/+' | head -c 32)
    local etcd_key=$(openssl rand -base64 32)
    
    # Replace placeholders with generated passwords
    sed -i "s/your-strong-haproxy-stats-password/$haproxy_pass/g" "$vault_file"
    sed -i "s/your-strong-k8s-admin-password/$admin_pass/g" "$vault_file"
    sed -i "s/your-bootstrap-token-here/$bootstrap_token/g" "$vault_file"
    sed -i "s/your-ca-key-passphrase/$ca_passphrase/g" "$vault_file"
    sed -i "s|your-etcd-encryption-key-here|$etcd_key|g" "$vault_file"
    
    # Encrypt the vault file
    log_info "Encrypting vault file..."
    ansible-vault encrypt "$vault_file"
    
    log_success "Vault file created and encrypted: $vault_file"
    log_info "Generated credentials:"
    echo "  - HAProxy Stats Password: $haproxy_pass"
    echo "  - K8s Admin Password: $admin_pass"
    echo "  - Bootstrap Token: $bootstrap_token"
    log_warning "Save these credentials securely!"
}

# Run a playbook
run_playbook() {
    local playbook="$1"
    local description="$2"
    
    log_info "$description"
    
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
    
    # Run the playbook
    cd "$PLAYBOOK_DIR"
    if ansible-playbook -i "$INVENTORY_FILE" "$playbook" $ansible_opts; then
        log_success "$description completed successfully"
    else
        log_error "$description failed"
        exit 1
    fi
}

# Stage 1: Setup HAProxy and prepare nodes
stage1() {
    log_stage "Stage 1: Infrastructure Preparation"
    
    run_playbook "stage1-preparation/01-setup-haproxy.yml" "Setting up HAProxy load balancer"
    run_playbook "stage1-preparation/02-prepare-nodes.yml" "Preparing Kubernetes nodes"
    
    log_success "Stage 1 completed: Infrastructure ready for Kubernetes"
}

# Stage 2: Initialize cluster and join nodes
stage2() {
    log_stage "Stage 2: Cluster Initialization"
    
    run_playbook "stage2-cluster/01-init-first-master.yml" "Initializing first master node"
    run_playbook "stage2-cluster/02-join-masters.yml" "Joining additional master nodes"
    run_playbook "stage2-cluster/03-join-workers.yml" "Joining worker nodes"
    
    if [[ "$SKIP_VERIFY" != "true" ]]; then
        run_playbook "stage2-cluster/04-verify-cluster.yml" "Verifying cluster health"
    fi
    
    log_success "Stage 2 completed: Kubernetes cluster is operational"
}

# Stage 3: Install essential services
stage3() {
    log_stage "Stage 3: Essential Services Installation"
    
    run_playbook "stage3-services/01-install-essentials.yml" "Installing essential services"
    
    log_success "Stage 3 completed: Essential services installed"
}

# Full deployment
full_deploy() {
    log_stage "Full Kubernetes Cluster Deployment"
    
    stage1
    log_info "Waiting for nodes to settle..."
    sleep 30
    
    stage2
    log_info "Waiting for cluster to stabilize..."
    sleep 30
    
    stage3
    
    log_success "Full Kubernetes deployment completed successfully!"
    
    # Display deployment summary
    log_info "Deployment Summary:"
    echo "==================="
    echo "Kubernetes cluster has been successfully deployed!"
    echo ""
    echo "Cluster Configuration:"
    echo "- Masters: 3 nodes (HA setup)"
    echo "- Workers: 6 nodes"
    echo "- Load Balancer: HAProxy on 10.100.10.210"
    echo "- API Endpoint: https://10.100.10.210:6443"
    echo ""
    echo "Access Information:"
    echo "- Download kubeconfig: $0 get-kubeconfig"
    echo "- Get dashboard token: $0 get-dashboard-token"
    echo "- HAProxy stats: http://10.100.10.210:8404/stats"
    echo ""
    echo "Next Steps:"
    echo "1. Download and configure kubectl with the kubeconfig"
    echo "2. Access the Kubernetes Dashboard"
    echo "3. Deploy your applications"
}

# Verify cluster
verify_cluster() {
    log_info "Verifying Kubernetes cluster..."
    run_playbook "stage2-cluster/04-verify-cluster.yml" "Cluster verification"
}

# Get kubeconfig
get_kubeconfig() {
    log_info "Downloading kubeconfig file..."
    
    local kubeconfig_file="./kubeconfig"
    
    if [[ -f "$kubeconfig_file" ]]; then
        log_success "Kubeconfig file is available: $kubeconfig_file"
        echo "To use kubectl:"
        echo "export KUBECONFIG=$PWD/kubeconfig"
        echo "kubectl get nodes"
    else
        log_error "Kubeconfig file not found. Run cluster initialization first."
        exit 1
    fi
}

# Get dashboard token
get_dashboard_token() {
    log_info "Getting Kubernetes Dashboard token..."
    
    cd "$PLAYBOOK_DIR"
    ansible k8s_masters[0] -i "$INVENTORY_FILE" -m shell \
        -a "kubectl -n kubernetes-dashboard create token admin-user" \
        -b --become-user=root
}

# Destroy cluster (dangerous)
destroy_cluster() {
    log_warning "This will completely destroy the Kubernetes cluster!"
    
    if [[ "$FORCE_MODE" != "true" ]]; then
        read -p "Are you sure you want to destroy the cluster? Type 'DESTROY' to confirm: " -r
        if [[ "$REPLY" != "DESTROY" ]]; then
            log_info "Cluster destruction cancelled"
            return 0
        fi
    fi
    
    log_info "Destroying Kubernetes cluster..."
    
    # Reset all nodes
    ansible k8s_masters:k8s_workers -i "$INVENTORY_FILE" -m shell \
        -a "kubeadm reset --force" -b
    
    # Clean up
    ansible k8s_masters:k8s_workers -i "$INVENTORY_FILE" -m shell \
        -a "rm -rf /etc/kubernetes /var/lib/etcd ~/.kube" -b
    
    log_success "Kubernetes cluster destroyed"
}

# Main function
main() {
    local command=""
    
    # Default options
    VAULT_PASS="false"
    CHECK_MODE="false"
    VERBOSE_MODE="false"
    FORCE_MODE="false"
    SKIP_VERIFY="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            stage1|stage2|stage3|full-deploy|verify|create-vault|get-kubeconfig|get-dashboard-token|destroy|help)
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
            --skip-verify)
                SKIP_VERIFY="true"
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
        stage1)
            stage1
            ;;
        stage2)
            stage2
            ;;
        stage3)
            stage3
            ;;
        full-deploy)
            full_deploy
            ;;
        verify)
            verify_cluster
            ;;
        create-vault)
            create_vault
            ;;
        get-kubeconfig)
            get_kubeconfig
            ;;
        get-dashboard-token)
            get_dashboard_token
            ;;
        destroy)
            destroy_cluster
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