# Docker Template Deployment Guide

This guide covers deployment strategies and best practices for the Docker template.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Harbor registry access
- Kubernetes cluster (for production deployment)

## Environment Setup

### Development Environment

```bash
# 1. Clone the template
git clone <repository-url>
cd docker-template

# 2. Initialize the project
./scripts/setup.sh

# 3. Start development environment
make up
# or
docker-compose -f docker-compose.dev.yml up -d
```

### Production Environment

```bash
# 1. Build production image
make build

# 2. Run security checks
make security

# 3. Push to Harbor
make harbor-push

# 4. Deploy to production
make deploy-prod
```

## Deployment Strategies

### Docker Compose Deployment

```bash
# Development
docker-compose -f docker-compose.dev.yml up -d

# Production
docker-compose -f docker-compose.yml up -d
```

### Kubernetes Deployment

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -l app=my-docker-project

# Check service
kubectl get svc my-docker-project-service
```

### Blue-Green Deployment

```bash
# Deploy to green environment
export COMPOSE_PROJECT_NAME=myapp-green
docker-compose -f docker-compose.yml up -d

# Test green environment
curl http://localhost/health

# Switch traffic (using load balancer)
# Update load balancer configuration

# Remove blue environment
export COMPOSE_PROJECT_NAME=myapp-blue
docker-compose -f docker-compose.yml down
```

## Configuration Management

### Environment Variables

- `.env` - Default configuration
- `.env.prod` - Production configuration
- `.env.staging` - Staging configuration
- `.env.harbor` - Harbor registry configuration

### Secrets Management

For production deployments, use proper secrets management:

```bash
# Kubernetes secrets
kubectl create secret generic app-secrets \
  --from-literal=db-password=secretpassword \
  --from-literal=jwt-secret=jwtsecret

# Docker secrets
echo "secretpassword" | docker secret create db_password -
```

## Monitoring and Logging

### Health Checks

The application provides health check endpoints:

- `/health` - Application health status
- `/ready` - Readiness probe for Kubernetes

### Logging

Logs are configured with structured logging:

```bash
# View application logs
docker-compose logs -f app

# View all service logs
docker-compose logs -f

# Follow logs with filtering
docker-compose logs -f app | grep ERROR
```

### Monitoring Stack

The template includes Prometheus and Grafana:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001

## Security Considerations

### Image Security

1. Use multi-stage builds
2. Run as non-root user
3. Minimize attack surface
4. Regular vulnerability scanning

### Network Security

1. Use custom Docker networks
2. Limit exposed ports
3. Implement proper firewall rules
4. Use TLS for external communication

### Secrets Security

1. Never commit secrets to version control
2. Use environment variables or secret management
3. Rotate secrets regularly
4. Limit access to secrets

## Troubleshooting

### Common Issues

1. **Port conflicts**: Change ports in docker-compose files
2. **Permission issues**: Check file ownership and permissions
3. **Memory issues**: Increase Docker memory limits
4. **Network issues**: Check Docker network configuration

### Debug Commands

```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs app

# Execute shell in container
docker-compose exec app sh

# Check resource usage
docker stats

# Inspect container
docker inspect <container-name>
```

### Performance Tuning

1. **Image optimization**: Use alpine images, minimize layers
2. **Resource limits**: Set appropriate CPU and memory limits
3. **Caching**: Use Docker build cache effectively
4. **Storage**: Use appropriate storage drivers

## Backup and Recovery

### Database Backup

```bash
# PostgreSQL backup
docker-compose exec db pg_dump -U appuser myapp > backup.sql

# Restore
docker-compose exec -T db psql -U appuser myapp < backup.sql
```

### Volume Backup

```bash
# Create volume backup
docker run --rm -v myapp_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_backup.tar.gz /data

# Restore volume
docker run --rm -v myapp_postgres_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/postgres_backup.tar.gz -C /
```

## Scaling

### Horizontal Scaling

```bash
# Scale application containers
docker-compose up -d --scale app=3

# Kubernetes scaling
kubectl scale deployment my-docker-project --replicas=3
```

### Load Balancing

Configure load balancer (nginx, traefik, etc.) to distribute traffic:

```nginx
upstream app_backend {
    server app1:3000;
    server app2:3000;
    server app3:3000;
}

server {
    listen 80;
    
    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```