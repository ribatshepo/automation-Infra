#!/bin/bash
set -e

echo "Setting up CI/CD integration..."

# Create GitHub Actions workflow
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: automation-infra/cicd-templates/.github/workflows/main-python-deploy.yml@main
    with:
      python_version: "3.9"
      project_name: "project-name"
      run_tests: true
      run_security_scan: true
      deploy_to_registry: false
      registry_url: "harbor.your-domain.com"
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      REGISTRY_USERNAME: ${{ secrets.REGISTRY_USERNAME }}
      REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
EOF

# Create deployment workflow
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    uses: automation-infra/cicd-templates/.github/workflows/main-python-deploy.yml@main
    with:
      python_version: "3.9"
      project_name: "project-name"
      environment: ${{ github.event.inputs.environment || 'production' }}
      run_tests: true
      run_security_scan: true
      deploy_to_registry: true
      deploy_to_kubernetes: true
      registry_url: "harbor.your-domain.com"
      kubernetes_namespace: ${{ github.event.inputs.environment || 'production' }}
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      REGISTRY_USERNAME: ${{ secrets.REGISTRY_USERNAME }}
      REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
# Multi-stage build for Python application
FROM python:3.9-slim as builder

# Install UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Production stage
FROM python:3.9-slim as production

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Copy source code
COPY src/ ./src/

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/src"

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import src.project_name; print('OK')" || exit 1

# Run application
CMD ["python", "-m", "src.project_name.main"]
EOF

# Create .dockerignore
cat > .dockerignore << 'EOF'
.git
.gitignore
README.md
Dockerfile
.dockerignore
.github
.venv
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env
pip-log.txt
pip-delete-this-directory.txt
.tox
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.mypy_cache
.pytest_cache
htmlcov
.DS_Store
docs/
examples/
tests/
scripts/
*.md
EOF

# Create Kubernetes manifests
mkdir -p k8s

cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: PROJECT_NAME
  namespace: NAMESPACE
  labels:
    app: PROJECT_NAME
    version: VERSION
spec:
  replicas: 3
  selector:
    matchLabels:
      app: PROJECT_NAME
  template:
    metadata:
      labels:
        app: PROJECT_NAME
        version: VERSION
    spec:
      containers:
      - name: PROJECT_NAME
        image: REGISTRY_URL/PROJECT_NAME:VERSION
        ports:
        - containerPort: 8000
        env:
        - name: ENVIRONMENT
          value: "ENVIRONMENT"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
EOF

cat > k8s/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: PROJECT_NAME
  namespace: NAMESPACE
  labels:
    app: PROJECT_NAME
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: PROJECT_NAME
EOF

cat > k8s/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: PROJECT_NAME
  namespace: NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - PROJECT_NAME.your-domain.com
    secretName: PROJECT_NAME-tls
  rules:
  - host: PROJECT_NAME.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: PROJECT_NAME
            port:
              number: 80
EOF

# Create Helm chart
mkdir -p helm/project-name/templates

cat > helm/project-name/Chart.yaml << 'EOF'
apiVersion: v2
name: project-name
description: A Helm chart for Python project
type: application
version: 0.1.0
appVersion: "0.1.0"
EOF

cat > helm/project-name/values.yaml << 'EOF'
replicaCount: 3

image:
  repository: harbor.your-domain.com/project-name
  pullPolicy: IfNotPresent
  tag: ""

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: project-name.your-domain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: project-name-tls
      hosts:
        - project-name.your-domain.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
    - ALL
EOF

echo "CI/CD integration setup complete!"
echo ""
echo "Created files:"
echo "- .github/workflows/ci.yml (CI pipeline)"
echo "- .github/workflows/deploy.yml (Deployment pipeline)"
echo "- Dockerfile (Container image)"
echo "- k8s/ (Kubernetes manifests)"
echo "- helm/ (Helm chart)"
echo ""
echo "Next steps:"
echo "1. Update project name in workflow files"
echo "2. Configure GitHub repository secrets:"
echo "   - HARBOR_USERNAME"
echo "   - HARBOR_PASSWORD"
echo "   - REGISTRY_USERNAME"
echo "   - REGISTRY_PASSWORD"
echo "   - KUBECONFIG"
echo "3. Update domain names in ingress configurations"
echo "4. Commit and push to trigger CI/CD pipeline"