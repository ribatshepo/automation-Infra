# Ansible Infrastructure Automation - Makefile
# Provides convenient targets for deploying, verifying, and managing infrastructure services

# Variables
INVENTORY ?= inventory.yml
VAULT_PASS_FILE ?= ~/.ansible_vault_pass
ANSIBLE_OPTS ?= -i $(INVENTORY)
VERBOSE ?= -v

# Check if vault password file exists, if so add it to options
ifneq ($(wildcard $(VAULT_PASS_FILE)),)
    ANSIBLE_OPTS += --vault-password-file $(VAULT_PASS_FILE)
else
    ANSIBLE_OPTS += --ask-vault-pass
endif

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
PURPLE = \033[0;35m
CYAN = \033[0;36m
NC = \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

##@ General Commands

.PHONY: help
help: ## Display this help message
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║              Ansible Infrastructure Automation               ║$(NC)"
	@echo "$(PURPLE)║                    Makefile Commands                         ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(CYAN)<target>$(NC)\n\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: check-requirements
check-requirements: ## Check if all required tools are installed
	@echo "$(BLUE) Checking requirements...$(NC)"
	@command -v ansible >/dev/null 2>&1 || { echo "$(RED) Ansible is not installed$(NC)"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "$(RED) Docker is not installed$(NC)"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "$(RED) Git is not installed$(NC)"; exit 1; }
	@test -f $(INVENTORY) || { echo "$(RED) Inventory file $(INVENTORY) not found$(NC)"; exit 1; }
	@echo "$(GREEN) All requirements satisfied$(NC)"

.PHONY: ping
ping: check-requirements ## Test connectivity to all hosts
	@echo "$(BLUE) Testing connectivity to all hosts...$(NC)"
	@ansible $(ANSIBLE_OPTS) all -m ping $(VERBOSE)

##@ Deployment Commands

.PHONY: deploy-all
deploy-all: check-requirements ## Deploy all infrastructure services
	@echo "$(PURPLE) Deploying all infrastructure services...$(NC)"
	@$(MAKE) deploy-postgres
	@$(MAKE) deploy-redis
	@$(MAKE) deploy-minio
	@$(MAKE) deploy-harbor
	@$(MAKE) deploy-jfrog
	@$(MAKE) deploy-kubernetes
	@$(MAKE) deploy-qemu-agent
	@echo "$(GREEN) All services deployed successfully!$(NC)"

.PHONY: deploy-harbor
deploy-harbor: check-requirements ## Deploy Harbor container registry
	@echo "$(BLUE) Deploying Harbor container registry...$(NC)"
	@cd harbor && ./deploy-harbor.sh
	@echo "$(GREEN) Harbor deployed$(NC)"

.PHONY: deploy-jfrog
deploy-jfrog: check-requirements ## Deploy JFrog Artifactory
	@echo "$(BLUE) Deploying JFrog Artifactory...$(NC)"
	@cd jfrog && ./deploy-artifactory-enhanced.sh
	@echo "$(GREEN) JFrog Artifactory deployed$(NC)"

.PHONY: deploy-postgres
deploy-postgres: check-requirements ## Deploy PostgreSQL database
	@echo "$(BLUE) Deploying PostgreSQL database...$(NC)"
	@cd postgres && ./deploy-postgresql.sh
	@echo "$(GREEN) PostgreSQL deployed$(NC)"

.PHONY: deploy-redis
deploy-redis: check-requirements ## Deploy Redis data store
	@echo "$(BLUE) Deploying Redis data store...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) redis/install-redis.yml $(VERBOSE)
	@echo "$(GREEN) Redis deployed$(NC)"

.PHONY: deploy-minio
deploy-minio: check-requirements ## Deploy MinIO object storage
	@echo "$(BLUE) Deploying MinIO object storage...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) minio/install-minio.yml $(VERBOSE)
	@echo "$(GREEN) MinIO deployed$(NC)"

.PHONY: deploy-kubernetes
deploy-kubernetes: check-requirements ## Deploy Kubernetes cluster
	@echo "$(BLUE) Deploying Kubernetes cluster...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) kubernetes/install-kubernetes.yml $(VERBOSE)
	@echo "$(GREEN) Kubernetes deployed$(NC)"

.PHONY: deploy-nexus
deploy-nexus: check-requirements ## Deploy Nexus repository manager
	@echo "$(BLUE) Deploying Nexus repository manager...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) nexus/install-nexus.yml $(VERBOSE)
	@echo "$(GREEN) Nexus deployed$(NC)"

.PHONY: deploy-qemu-agent
deploy-qemu-agent: check-requirements ## Deploy QEMU Guest Agent
	@echo "$(BLUE) Deploying QEMU Guest Agent...$(NC)"
	@cd qemu-agent && ./deploy-qemu-guest-agent.sh
	@echo "$(GREEN) QEMU Guest Agent deployed$(NC)"

##@ Verification Commands

.PHONY: verify-all
verify-all: check-requirements ## Verify all deployed services
	@echo "$(PURPLE) Verifying all services...$(NC)"
	@$(MAKE) verify-postgres
	@$(MAKE) verify-harbor
	@$(MAKE) verify-qemu-agent
	@echo "$(GREEN) All services verified successfully!$(NC)"

.PHONY: verify-harbor
verify-harbor: check-requirements ## Verify Harbor deployment
	@echo "$(BLUE) Verifying Harbor...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) harbor/verify-harbor.yml $(VERBOSE) || echo "$(YELLOW) Harbor verification playbook not found$(NC)"
	@echo "$(GREEN) Harbor verification complete$(NC)"

.PHONY: verify-jfrog
verify-jfrog: check-requirements ## Verify JFrog Artifactory deployment
	@echo "$(BLUE) Verifying JFrog Artifactory...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) jfrog/verify-artifactory.yml $(VERBOSE) || echo "$(YELLOW) JFrog verification playbook not found$(NC)"
	@echo "$(GREEN) JFrog verification complete$(NC)"

.PHONY: verify-postgres
verify-postgres: check-requirements ## Verify PostgreSQL deployment
	@echo "$(BLUE) Verifying PostgreSQL...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) postgres/verify-postgresql.yml $(VERBOSE)
	@echo "$(GREEN) PostgreSQL verification complete$(NC)"

.PHONY: verify-qemu-agent
verify-qemu-agent: check-requirements ## Verify QEMU Guest Agent deployment
	@echo "$(BLUE) Verifying QEMU Guest Agent...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) qemu-agent/verify-qemu-guest-agent.yml $(VERBOSE)
	@echo "$(GREEN) QEMU Guest Agent verification complete$(NC)"

##@ Maintenance Commands

.PHONY: maintenance-all
maintenance-all: check-requirements ## Run maintenance tasks for all services
	@echo "$(PURPLE) Running maintenance for all services...$(NC)"
	@$(MAKE) maintenance-postgres
	@echo "$(GREEN) All maintenance tasks completed!$(NC)"

.PHONY: maintenance-postgres
maintenance-postgres: check-requirements ## Run PostgreSQL maintenance tasks
	@echo "$(BLUE) Running PostgreSQL maintenance...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) postgres/maintenance-postgresql.yml $(VERBOSE)
	@echo "$(GREEN) PostgreSQL maintenance complete$(NC)"

.PHONY: backup-postgres
backup-postgres: check-requirements ## Backup PostgreSQL databases
	@echo "$(BLUE) Backing up PostgreSQL databases...$(NC)"
	@ansible-playbook $(ANSIBLE_OPTS) postgres/backup-postgresql.yml $(VERBOSE) || echo "$(YELLOW) PostgreSQL backup playbook not found$(NC)"
	@echo "$(GREEN) PostgreSQL backup complete$(NC)"

##@ CI/CD Commands

.PHONY: setup-cicd
setup-cicd: ## Setup CI/CD templates for a project
	@echo "$(BLUE) Setting up CI/CD templates...$(NC)"
	@echo "$(YELLOW)Please specify target directory: make setup-cicd TARGET=/path/to/project$(NC)"
	@echo "$(YELLOW)Or run interactively: cd cicd-templates && ./setup.sh /path/to/project --interactive$(NC)"

.PHONY: setup-cicd-interactive
setup-cicd-interactive: ## Setup CI/CD templates interactively
	@echo "$(BLUE) Setting up CI/CD templates interactively...$(NC)"
	@read -p "Enter target project directory: " target_dir; \
	cd cicd-templates && ./setup.sh "$$target_dir" --interactive

.PHONY: configure-secrets
configure-secrets: ## Configure GitHub secrets for CI/CD
	@echo "$(BLUE) Configuring GitHub secrets...$(NC)"
	@cd cicd-templates && ./configure-secrets.sh --template
	@echo "$(GREEN) Secrets template generated$(NC)"
	@echo "$(CYAN) Check github-secrets-configuration.md for setup instructions$(NC)"

.PHONY: configure-secrets-interactive
configure-secrets-interactive: ## Configure GitHub secrets interactively
	@echo "$(BLUE) Configuring GitHub secrets interactively...$(NC)"
	@cd cicd-templates && ./configure-secrets.sh --interactive

.PHONY: validate-secrets
validate-secrets: ## Validate GitHub secrets configuration
	@echo "$(BLUE) Validating secrets configuration...$(NC)"
	@cd cicd-templates && ./validate-secrets.sh

##@ Development Commands

.PHONY: dev-setup
dev-setup: ## Setup minimal development environment
	@echo "$(BLUE) Setting up development environment...$(NC)"
	@$(MAKE) deploy-harbor
	@$(MAKE) deploy-jfrog
	@$(MAKE) deploy-postgres
	@echo "$(GREEN) Development environment ready$(NC)"

.PHONY: prod-setup
prod-setup: ## Setup full production environment
	@echo "$(BLUE) Setting up production environment...$(NC)"
	@$(MAKE) deploy-all
	@$(MAKE) verify-all
	@$(MAKE) maintenance-all
	@echo "$(GREEN) Production environment ready$(NC)"

##@ Cleanup Commands

.PHONY: stop-all
stop-all: ## Stop all running services
	@echo "$(YELLOW) Stopping all services...$(NC)"
	@ansible $(ANSIBLE_OPTS) all -m shell -a "docker stop \$$(docker ps -q) || true" $(VERBOSE)
	@echo "$(GREEN) All services stopped$(NC)"

.PHONY: clean-docker
clean-docker: ## Clean up Docker resources
	@echo "$(YELLOW) Cleaning Docker resources...$(NC)"
	@ansible $(ANSIBLE_OPTS) all -m shell -a "docker system prune -f" $(VERBOSE)
	@echo "$(GREEN) Docker cleanup complete$(NC)"

##@ Information Commands

.PHONY: status
status: check-requirements ## Show status of all services
	@echo "$(BLUE) Checking service status...$(NC)"
	@echo "$(CYAN) Harbor (Port 8080):$(NC)"
	@ansible $(ANSIBLE_OPTS) all -m uri -a "url=http://{{ ansible_host }}:8080 method=GET" $(VERBOSE) || echo "$(RED) Harbor not accessible$(NC)"
	@echo "$(CYAN) JFrog Artifactory (Port 8081):$(NC)"
	@ansible $(ANSIBLE_OPTS) all -m uri -a "url=http://{{ ansible_host }}:8081 method=GET" $(VERBOSE) || echo "$(RED) JFrog not accessible$(NC)"
	@echo "$(CYAN) MinIO (Port 9000):$(NC)"
	@ansible $(ANSIBLE_OPTS) all -m uri -a "url=http://{{ ansible_host }}:9000 method=GET" $(VERBOSE) || echo "$(RED) MinIO not accessible$(NC)"

.PHONY: endpoints
endpoints: ## Show service endpoints
	@echo "$(BLUE) Service Endpoints:$(NC)"
	@echo "$(CYAN) Harbor:$(NC) http://10.100.10.215:8080"
	@echo "$(CYAN) JFrog Artifactory:$(NC) http://10.100.10.215:8081"
	@echo "$(CYAN) MinIO:$(NC) http://10.100.10.215:9000"
	@echo "$(CYAN) PostgreSQL:$(NC) 10.100.10.215:5432"
	@echo "$(CYAN) Redis:$(NC) 10.100.10.215:6379"

.PHONY: logs
logs: ## Show logs for services
	@echo "$(BLUE) Service Logs:$(NC)"
	@echo "$(YELLOW)Harbor logs:$(NC) /var/log/harbor/"
	@echo "$(YELLOW)JFrog logs:$(NC) /opt/jfrog/artifactory/var/log/"
	@echo "$(YELLOW)PostgreSQL logs:$(NC) /var/log/postgresql/"
	@echo "$(YELLOW)Ansible logs:$(NC) ./ansible.log"

##@ Advanced Commands

.PHONY: vault-edit-harbor
vault-edit-harbor: ## Edit Harbor vault file
	@echo "$(BLUE) Editing Harbor vault...$(NC)"
	@ansible-vault edit harbor/vault.yml

.PHONY: vault-edit-jfrog
vault-edit-jfrog: ## Edit JFrog vault file
	@echo "$(BLUE) Editing JFrog vault...$(NC)"
	@ansible-vault edit jfrog/vault.yml

.PHONY: vault-edit-postgres
vault-edit-postgres: ## Edit PostgreSQL vault file
	@echo "$(BLUE) Editing PostgreSQL vault...$(NC)"
	@ansible-vault edit postgres/vault.yml

.PHONY: update-all
update-all: check-requirements ## Update all services to latest versions
	@echo "$(BLUE) Updating all services...$(NC)"
	@echo "$(YELLOW) This will update all services to their latest versions$(NC)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(MAKE) deploy-all; \
	else \
		echo "$(YELLOW)Update cancelled$(NC)"; \
	fi

##@ CI/CD Specific Targets

.PHONY: cicd-summary
cicd-summary: ## Show CI/CD templates summary
	@echo "$(BLUE) CI/CD Templates Summary:$(NC)"
	@cd cicd-templates && ./show-summary.sh

.PHONY: cicd-test-workflow
cicd-test-workflow: ## Generate test workflow for GitHub Actions
	@echo "$(BLUE) Generating CI/CD test workflow...$(NC)"
	@cd cicd-templates && ./validate-secrets.sh workflow

# Special target for setting up CI/CD with directory argument
setup-cicd-target: ## Internal target for CI/CD setup with TARGET variable
ifdef TARGET
	@echo "$(BLUE) Setting up CI/CD for $(TARGET)...$(NC)"
	@cd cicd-templates && ./setup.sh $(TARGET) --interactive
else
	@echo "$(RED) TARGET directory not specified$(NC)"
	@echo "$(YELLOW)Usage: make setup-cicd-target TARGET=/path/to/project$(NC)"
endif

##@ Documentation

.PHONY: docs
docs: ## Show documentation links
	@echo "$(BLUE) Documentation:$(NC)"
	@echo "$(CYAN) Main README:$(NC) ./README.md"
	@echo "$(CYAN) Harbor:$(NC) ./harbor/README.md"
	@echo "$(CYAN) JFrog:$(NC) ./jfrog/README.md"
	@echo "$(CYAN) PostgreSQL:$(NC) ./postgres/README.md"
	@echo "$(CYAN) CI/CD Templates:$(NC) ./cicd-templates/README.md"
	@echo "$(CYAN) CI/CD Overview:$(NC) ./cicd-templates/OVERVIEW.md"
	@echo "$(CYAN) Getting Started:$(NC) ./cicd-templates/docs/getting-started.md"

.PHONY: version
version: ## Show version information
	@echo "$(BLUE) Version Information:$(NC)"
	@echo "$(CYAN)Ansible:$(NC) $$(ansible --version | head -1)"
	@echo "$(CYAN)Docker:$(NC) $$(docker --version)"
	@echo "$(CYAN)Git:$(NC) $$(git --version)"
	@echo "$(CYAN)Make:$(NC) $$(make --version | head -1)"