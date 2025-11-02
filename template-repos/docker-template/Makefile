# Docker Template Makefile
# Provides common tasks for Docker development workflow

.PHONY: help build test lint format security clean deploy setup

# Configuration
IMAGE_NAME ?= $(shell basename $(CURDIR))
IMAGE_TAG ?= latest
ENVIRONMENT ?= development
HARBOR_URL ?= harbor.local
HARBOR_PROJECT ?= library

# Default target
help: ## Show this help message
	@echo "Docker Template Makefile"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Initialize the project
	@echo "Setting up Docker template..."
	./scripts/setup.sh

build: ## Build Docker image
	@echo "Building Docker image: $(IMAGE_NAME):$(IMAGE_TAG)"
	./scripts/build.sh $(IMAGE_NAME) $(IMAGE_TAG)

build-dev: ## Build development Docker image
	@echo "Building development Docker image..."
	docker build -t $(IMAGE_NAME):dev -f Dockerfile.dev .

test: ## Run application tests
	@echo "Running tests..."
	cd app && npm test

lint: ## Run code linting
	@echo "Running linters..."
	cd app && npm run lint

format: ## Format code
	@echo "Formatting code..."
	cd app && npm run format

security: ## Run security checks
	@echo "Running security checks..."
	./scripts/security-check.sh $(IMAGE_NAME) $(IMAGE_TAG)

security-full: ## Run comprehensive security checks
	@echo "Running comprehensive security checks..."
	./scripts/security-check.sh $(IMAGE_NAME) $(IMAGE_TAG)
	@if command -v docker-bench-security >/dev/null 2>&1; then \
		echo "Running Docker Bench Security..."; \
		docker run --rm --net host --pid host --userns host --cap-add audit_control \
			-v /etc:/etc:ro \
			-v /usr/bin/containerd:/usr/bin/containerd:ro \
			-v /usr/bin/runc:/usr/bin/runc:ro \
			-v /usr/lib/systemd:/usr/lib/systemd:ro \
			-v /var/lib:/var/lib:ro \
			-v /var/run/docker.sock:/var/run/docker.sock:ro \
			docker/docker-bench-security; \
	fi

deploy: ## Deploy to specified environment
	@echo "Deploying to $(ENVIRONMENT) environment..."
	./scripts/deploy.sh $(ENVIRONMENT)

deploy-dev: ## Deploy to development environment
	@echo "Deploying to development environment..."
	./scripts/deploy.sh development

deploy-prod: ## Deploy to production environment
	@echo "Deploying to production environment..."
	./scripts/deploy.sh production

up: ## Start development environment
	@echo "Starting development environment..."
	docker-compose -f docker-compose.dev.yml up -d

down: ## Stop development environment
	@echo "Stopping development environment..."
	docker-compose -f docker-compose.dev.yml down

logs: ## Show logs from development environment
	@echo "Showing logs from development environment..."
	docker-compose -f docker-compose.dev.yml logs -f

restart: ## Restart development environment
	@echo "Restarting development environment..."
	docker-compose -f docker-compose.dev.yml restart

clean: ## Clean containers and images
	@echo "Cleaning Docker resources..."
	./scripts/clean.sh containers

clean-all: ## Clean all Docker resources
	@echo "Cleaning all Docker resources..."
	./scripts/clean.sh all

clean-images: ## Clean unused images
	@echo "Cleaning unused images..."
	./scripts/clean.sh images

clean-volumes: ## Clean unused volumes
	@echo "Cleaning unused volumes..."
	./scripts/clean.sh volumes

harbor-push: ## Push image to Harbor registry
	@echo "Pushing to Harbor registry..."
	./scripts/harbor.sh push $(IMAGE_NAME) $(IMAGE_TAG)

harbor-scan: ## Trigger Harbor vulnerability scan
	@echo "Triggering Harbor vulnerability scan..."
	./scripts/harbor.sh scan $(IMAGE_NAME) $(IMAGE_TAG)

harbor-list: ## List images in Harbor project
	@echo "Listing Harbor images..."
	./scripts/harbor.sh list

setup-cicd: ## Setup CI/CD integration
	@echo "Setting up CI/CD integration..."
	./scripts/setup-cicd.sh

install: ## Install application dependencies
	@echo "Installing application dependencies..."
	cd app && npm install

install-tools: ## Install development tools
	@echo "Installing development tools..."
	@if ! command -v hadolint >/dev/null 2>&1; then \
		echo "Installing Hadolint..."; \
		wget -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64; \
		chmod +x /tmp/hadolint; \
		sudo mv /tmp/hadolint /usr/local/bin/hadolint || mv /tmp/hadolint ./scripts/hadolint; \
	fi
	@if ! command -v trivy >/dev/null 2>&1; then \
		echo "Installing Trivy..."; \
		curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin; \
	fi

check: ## Run all checks (lint, test, security)
	@echo "Running all checks..."
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) security

ci: ## Run CI pipeline locally
	@echo "Running CI pipeline locally..."
	$(MAKE) install
	$(MAKE) check
	$(MAKE) build

release: ## Build and tag for release
	@echo "Building release image..."
	$(MAKE) build IMAGE_TAG=latest
	$(MAKE) build IMAGE_TAG=$(shell git rev-parse --short HEAD)
	@if [ -n "$(HARBOR_URL)" ]; then \
		echo "Tagging for Harbor..."; \
		docker tag $(IMAGE_NAME):latest $(HARBOR_URL)/$(HARBOR_PROJECT)/$(IMAGE_NAME):latest; \
		docker tag $(IMAGE_NAME):latest $(HARBOR_URL)/$(HARBOR_PROJECT)/$(IMAGE_NAME):$(shell git rev-parse --short HEAD); \
	fi

docs: ## Generate documentation
	@echo "Generating documentation..."
	@echo "# Docker Template Documentation" > docs/generated.md
	@echo "" >> docs/generated.md
	@echo "## Image Information" >> docs/generated.md
	@echo "- **Name**: $(IMAGE_NAME)" >> docs/generated.md
	@echo "- **Tag**: $(IMAGE_TAG)" >> docs/generated.md
	@echo "- **Harbor URL**: $(HARBOR_URL)" >> docs/generated.md
	@echo "- **Harbor Project**: $(HARBOR_PROJECT)" >> docs/generated.md
	@echo "" >> docs/generated.md
	@echo "## Available Make Targets" >> docs/generated.md
	@$(MAKE) help | grep -E "^  " >> docs/generated.md

health: ## Check application health
	@echo "Checking application health..."
	@if curl -f http://localhost:3000/health >/dev/null 2>&1; then \
		echo "Application is healthy"; \
	else \
		echo "Application is not responding"; \
		exit 1; \
	fi

status: ## Show Docker environment status
	@echo "Docker Environment Status"
	@echo "========================="
	@echo "Docker version:"
	@docker --version
	@echo ""
	@echo "Docker Compose version:"
	@docker-compose --version
	@echo ""
	@echo "Running containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "Image information:"
	@if docker images $(IMAGE_NAME) | grep -q $(IMAGE_NAME); then \
		docker images $(IMAGE_NAME); \
	else \
		echo "No images found for $(IMAGE_NAME)"; \
	fi