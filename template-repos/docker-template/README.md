# Docker Project Template

A comprehensive Docker template with multi-stage builds, Docker Compose configurations, and deployment scripts.

## Features

- **Multi-stage Builds**: Optimized Docker images with build and runtime stages
- **Security**: Rootless containers, security scanning, and best practices
- **Orchestration**: Docker Compose for local development and testing
- **CI/CD Integration**: GitHub Actions workflows from cicd-templates
- **Monitoring**: Health checks and logging configuration
- **Extensible**: Easy to customize for different application types

## Quick Start

### 1. Use This Template
```bash
# Create new repository from template
gh repo create my-docker-project --template automation-infra/docker-template
cd my-docker-project
```

### 2. Initialize Project
```bash
# Run setup script
./scripts/setup.sh

# Build containers
docker-compose build
```

### 3. Configure CI/CD
```bash
# Set up GitHub Actions (optional)
./scripts/setup-cicd.sh
```

## Project Structure

```
docker-template/
├── README.md                    # This file
├── .gitignore                   # Git ignore patterns
├── .dockerignore               # Docker ignore patterns
├── Dockerfile                  # Multi-stage production build
├── Dockerfile.dev              # Development build
├── docker-compose.yml          # Production compose
├── docker-compose.dev.yml      # Development compose
├── docker-compose.override.yml # Local overrides
├── .github/                    # GitHub workflows
│   └── workflows/
│       └── ci.yml              # Basic CI workflow
├── scripts/                    # Setup and utility scripts
│   ├── setup.sh               # Project initialization
│   ├── setup-cicd.sh          # CI/CD setup
│   ├── build.sh               # Build containers
│   ├── deploy.sh              # Deploy containers
│   ├── security-check.sh      # Security scanning
│   └── clean.sh               # Cleanup containers
├── config/                     # Configuration files
│   ├── nginx/                  # Nginx configuration
│   ├── prometheus/             # Monitoring config
│   └── grafana/               # Visualization config
├── app/                        # Application code
│   ├── src/                    # Source files
│   ├── public/                 # Static files
│   └── requirements.txt        # Dependencies (example)
├── k8s/                        # Kubernetes manifests
│   ├── deployment.yaml         # Application deployment
│   ├── service.yaml           # Service definition
│   └── ingress.yaml           # Ingress configuration
└── docs/                       # Documentation
    ├── deployment.md
    └── monitoring.md
```

## Docker Configuration

### Multi-stage Dockerfile
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:18-alpine AS production
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

### Docker Compose Configuration
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - db
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
```

## Development Workflow

### Local Development
```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up

# Build specific service
docker-compose build app

# View logs
docker-compose logs -f app

# Execute commands in container
docker-compose exec app bash
```

### Building and Testing
```bash
# Build all containers
./scripts/build.sh

# Run security scans
./scripts/security-check.sh

# Deploy to staging
./scripts/deploy.sh staging

# Clean up containers
./scripts/clean.sh
```

## Security Best Practices

### Container Security
- Use official base images
- Run as non-root user
- Minimize attack surface
- Scan for vulnerabilities
- Use multi-stage builds

### Network Security
- Use custom networks
- Limit exposed ports
- Implement proper service discovery
- Use secrets management

### Image Security
```dockerfile
# Use specific versions
FROM node:18.17.0-alpine3.18

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Set proper permissions
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Use HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

## CI/CD Integration

This template integrates with the automation-infra CI/CD templates:

### GitHub Actions Workflow
- Uses `cicd-templates/examples/main-docker-deploy.yml`
- Automated container building and testing
- Security scanning with Trivy
- Multi-platform builds
- Container registry publishing

### Workflow Configuration
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  docker:
    uses: automation-infra/cicd-templates/.github/workflows/main-docker-deploy.yml@main
    with:
      registry: "harbor.local"
      image_name: "my-docker-project"
      dockerfile: "Dockerfile"
      context: "."
      platforms: "linux/amd64,linux/arm64"
      scan_image: true
      push_image: true
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
```

## Kubernetes Deployment

### Basic Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: harbor.local/library/my-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

## Monitoring and Logging

### Health Checks
```bash
# Container health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Kubernetes liveness probe
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Logging Configuration
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    labels: "service,version"
```

## Environment Configurations

### Development (.env.dev)
```env
NODE_ENV=development
DB_HOST=db
DB_NAME=myapp_dev
DB_USER=dev_user
DB_PASSWORD=dev_password
REDIS_URL=redis://redis:6379
LOG_LEVEL=debug
```

### Production (.env.prod)
```env
NODE_ENV=production
DB_HOST=${DB_HOST}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
REDIS_URL=${REDIS_URL}
LOG_LEVEL=info
```

## Customization Examples

### Web Application
```dockerfile
FROM nginx:alpine AS web
COPY --from=builder /app/dist /usr/share/nginx/html
COPY config/nginx/default.conf /etc/nginx/conf.d/
EXPOSE 80
```

### Microservice
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest AS production
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]
```

### Database Migration
```dockerfile
FROM migrate/migrate AS migration
COPY migrations /migrations
ENTRYPOINT ["migrate", "-path", "/migrations", "-database", "${DATABASE_URL}"]
```

## Performance Optimization

### Build Optimization
- Use .dockerignore effectively
- Leverage Docker layer caching
- Use multi-stage builds
- Minimize base image size

### Runtime Optimization
- Use alpine images when possible
- Remove unnecessary packages
- Use distroless images for production
- Implement proper resource limits

## Security Scanning

### Image Scanning
```bash
# Trivy security scan
trivy image my-app:latest

# Docker security benchmark
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /etc:/etc:ro \
  -v /usr/bin/containerd:/usr/bin/containerd:ro \
  -v /usr/bin/runc:/usr/bin/runc:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --label docker_bench_security \
  docker/docker-bench-security
```

## Deployment Strategies

### Blue-Green Deployment
```bash
# Deploy to green environment
docker-compose -f docker-compose.green.yml up -d

# Switch traffic
./scripts/switch-traffic.sh green

# Remove blue environment
docker-compose -f docker-compose.blue.yml down
```

### Rolling Updates
```bash
# Update service with zero downtime
docker service update --image my-app:v2 my-app-service
```

## Troubleshooting

### Common Issues
```bash
# View container logs
docker-compose logs -f service-name

# Debug container
docker-compose exec service-name sh

# Check resource usage
docker stats

# Inspect network
docker network ls
docker network inspect network-name
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with Docker builds
5. Submit a pull request

## Support

- Documentation: [Project Docs](docs/)
- CI/CD Templates: [cicd-templates](../cicd-templates/)
- Issues: [GitHub Issues](https://github.com/your-org/project/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/project/discussions)