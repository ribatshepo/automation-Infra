#!/bin/bash
set -euo pipefail

echo "Setting up CI/CD integration..."

# Create GitHub Actions workflow
mkdir -p .github/workflows

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: automation-infra/cicd-templates/.github/workflows/main-go-deploy.yml@main
    with:
      go_version: "1.21"
      project_name: "project-name"
      run_tests: true
      run_benchmarks: true
      run_security_scan: true
      deploy_to_registry: false
      registry_url: "harbor.your-domain.com"
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
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
    uses: automation-infra/cicd-templates/.github/workflows/main-go-deploy.yml@main
    with:
      go_version: "1.21"
      project_name: "project-name"
      environment: ${{ github.event.inputs.environment || 'production' }}
      run_tests: true
      run_benchmarks: true
      run_security_scan: true
      deploy_to_registry: true
      deploy_to_kubernetes: true
      registry_url: "harbor.your-domain.com"
      kubernetes_namespace: ${{ github.event.inputs.environment || 'production' }}
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
# Multi-stage build for Go application
FROM golang:1.21-alpine AS builder

# Install dependencies for building
RUN apk add --no-cache git ca-certificates make

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build application
RUN make build

# Production stage
FROM alpine:latest AS production

# Install ca-certificates for SSL/TLS
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/bin/project-name .

# Create non-root user
RUN adduser -D -s /bin/sh appuser
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ./project-name --health-check || exit 1

# Start application
CMD ["./project-name"]
EOF

# Create .dockerignore
cat > .dockerignore << 'EOF'
.git
.github
.gitignore
README.md
Dockerfile
.dockerignore
coverage.out
coverage.html
bin/
scripts/
docs/
examples/
tests/
*.md
.golangci.yml
Makefile
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
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
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
    targetPort: 8080
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

echo "CI/CD integration setup complete!"
echo ""
echo "Created files:"
echo "- .github/workflows/ci.yml (CI pipeline)"
echo "- .github/workflows/deploy.yml (Deployment pipeline)"
echo "- Dockerfile (Container image)"
echo "- k8s/ (Kubernetes manifests)"
echo ""
echo "Next steps:"
echo "1. Update project name in workflow files"
echo "2. Configure GitHub repository secrets:"
echo "   - HARBOR_USERNAME"
echo "   - HARBOR_PASSWORD"
echo "   - KUBECONFIG"
echo "3. Update domain names in ingress configurations"
echo "4. Commit and push to trigger CI/CD pipeline"