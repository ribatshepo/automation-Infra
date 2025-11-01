#!/bin/bash
set -e

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
    uses: automation-infra/cicd-templates/.github/workflows/main-nodejs-deploy.yml@main
    with:
      node_version: "18"
      package_manager: "npm"
      project_name: "project-name"
      run_tests: true
      run_e2e_tests: false
      run_security_scan: true
      deploy_to_registry: false
      registry_url: "harbor.your-domain.com"
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
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
    uses: automation-infra/cicd-templates/.github/workflows/main-nodejs-deploy.yml@main
    with:
      node_version: "18"
      package_manager: "npm"
      project_name: "project-name"
      environment: ${{ github.event.inputs.environment || 'production' }}
      run_tests: true
      run_e2e_tests: true
      run_security_scan: true
      deploy_to_registry: true
      deploy_to_kubernetes: true
      registry_url: "harbor.your-domain.com"
      kubernetes_namespace: ${{ github.event.inputs.environment || 'production' }}
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
# Multi-stage build for Node.js application
FROM node:18-alpine AS builder

# Install dependencies for building native modules
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY src/ ./src/

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

WORKDIR /app

# Copy built application
COPY --from=builder --chown=nodeuser:nodejs /app/dist ./dist
COPY --from=builder --chown=nodeuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodeuser:nodejs /app/package.json ./package.json

# Switch to non-root user
USER nodeuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["npm", "start"]
EOF

# Create .dockerignore
cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
coverage
.git
.gitignore
README.md
.env
.nyc_output
.coverage
.coverage.*
tests
*.test.ts
*.spec.ts
.eslintrc.js
.prettierrc
jest.config.js
tsconfig.json
.github
docs
examples
scripts
.vscode
.idea
*.md
Dockerfile
.dockerignore
dist
build
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
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
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
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1001
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
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
    targetPort: 3000
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
    nginx.ingress.kubernetes.io/rate-limit: "100"
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

# Create load testing script
mkdir -p load-tests

cat > load-tests/basic-load-test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 0 },  // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.1'],   // Less than 10% of requests should fail
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function() {
  // Test health endpoint
  let healthResponse = http.get(`${BASE_URL}/health`);
  check(healthResponse, {
    'health status is 200': (r) => r.status === 200,
    'health response time < 200ms': (r) => r.timings.duration < 200,
  });

  // Test API endpoint
  let apiResponse = http.get(`${BASE_URL}/api`);
  check(apiResponse, {
    'api status is 200': (r) => r.status === 200,
    'api response time < 300ms': (r) => r.timings.duration < 300,
  });

  sleep(1);
}
EOF

echo "CI/CD integration setup complete!"
echo ""
echo "Created files:"
echo "- .github/workflows/ci.yml (CI pipeline)"
echo "- .github/workflows/deploy.yml (Deployment pipeline)"
echo "- Dockerfile (Container image)"
echo "- k8s/ (Kubernetes manifests)"
echo "- load-tests/ (Performance testing)"
echo ""
echo "Next steps:"
echo "1. Update project name in workflow files"
echo "2. Configure GitHub repository secrets:"
echo "   - HARBOR_USERNAME"
echo "   - HARBOR_PASSWORD"
echo "   - NPM_TOKEN"
echo "   - KUBECONFIG"
echo "3. Update domain names in ingress configurations"
echo "4. Commit and push to trigger CI/CD pipeline"