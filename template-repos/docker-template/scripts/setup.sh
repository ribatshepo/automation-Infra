#!/bin/bash

# Docker Template Setup Script
# Initializes a new Docker project with comprehensive configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME=${1:-"my-app"}
TEMPLATE_CONFIG=${2:-"template.config"}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Docker installation
check_docker() {
    print_status "Checking Docker installation..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_warning "docker-compose not found. Checking for docker compose plugin..."
        if ! docker compose version >/dev/null 2>&1; then
            print_error "Neither docker-compose nor docker compose plugin found."
            echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
            exit 1
        else
            print_success "Docker Compose plugin found"
            alias docker-compose='docker compose'
        fi
    else
        print_success "Docker Compose found"
    fi
    
    print_success "Docker environment is ready"
}

# Function to install optional tools
install_optional_tools() {
    print_status "Installing optional Docker tools..."
    
    # Install Hadolint for Dockerfile linting
    if ! command_exists hadolint; then
        print_status "Installing Hadolint (Dockerfile linter)..."
        if command_exists wget; then
            wget -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
            chmod +x /tmp/hadolint
            sudo mv /tmp/hadolint /usr/local/bin/hadolint 2>/dev/null || {
                print_warning "Could not install Hadolint system-wide. Installing locally..."
                mv /tmp/hadolint ./scripts/hadolint
            }
        else
            print_warning "wget not found. Skipping Hadolint installation."
        fi
    fi
    
    # Install Trivy for security scanning
    if ! command_exists trivy; then
        print_status "Installing Trivy (Security scanner)..."
        if command_exists curl; then
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null || {
                print_warning "Could not install Trivy system-wide. Manual installation required."
                print_status "Run: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ./scripts"
            }
        else
            print_warning "curl not found. Skipping Trivy installation."
        fi
    fi
    
    # Install dive for image analysis
    if ! command_exists dive; then
        print_status "Installing dive (Docker image analyzer)..."
        if command_exists wget && [[ "$OSTYPE" == "linux-gnu"* ]]; then
            DIVE_VERSION=$(curl -s "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            wget "https://github.com/wagoodman/dive/releases/latest/download/dive_${DIVE_VERSION}_linux_amd64.deb" -O /tmp/dive.deb
            sudo dpkg -i /tmp/dive.deb 2>/dev/null || {
                print_warning "Could not install dive system-wide. Manual installation required."
            }
            rm -f /tmp/dive.deb
        else
            print_warning "Skipping dive installation (Linux with wget required)."
        fi
    fi
}

# Function to create environment files
create_env_files() {
    print_status "Creating environment configuration files..."
    
    # Create .env.example
    cat > .env.example << 'EOF'
# Database Configuration
DB_NAME=myapp
DB_USER=appuser
DB_PASSWORD=your_secure_password_here

# Redis Configuration
REDIS_PASSWORD=your_redis_password_here

# Application Configuration
PORT=3000
NODE_ENV=production

# Monitoring Configuration
GRAFANA_USER=admin
GRAFANA_PASSWORD=your_grafana_password_here

# Docker Registry
DOCKER_REGISTRY=harbor.local
IMAGE_NAME=my-docker-project
IMAGE_TAG=latest

# Security
SECRET_KEY=your_secret_key_here
JWT_SECRET=your_jwt_secret_here

# External Services
EXTERNAL_API_URL=https://api.example.com
EXTERNAL_API_KEY=your_api_key_here
EOF

    # Create .env for development
    if [[ ! -f .env ]]; then
        cp .env.example .env
        print_success "Created .env file from template"
        print_warning "Please update .env with your actual configuration values"
    else
        print_warning ".env file already exists. Skipping creation."
    fi
    
    # Create .env.prod template
    cat > .env.prod.example << 'EOF'
# Production Environment Configuration
# Copy this file to .env.prod and update with production values

# Database Configuration
DB_NAME=myapp_prod
DB_USER=produser
DB_PASSWORD=CHANGE_ME_PRODUCTION_PASSWORD

# Redis Configuration
REDIS_PASSWORD=CHANGE_ME_REDIS_PASSWORD

# Application Configuration
PORT=3000
NODE_ENV=production

# Monitoring Configuration
GRAFANA_USER=admin
GRAFANA_PASSWORD=CHANGE_ME_GRAFANA_PASSWORD

# Docker Registry
DOCKER_REGISTRY=harbor.local
IMAGE_NAME=my-docker-project
IMAGE_TAG=latest

# Security (Generate strong secrets!)
SECRET_KEY=CHANGE_ME_SECRET_KEY
JWT_SECRET=CHANGE_ME_JWT_SECRET

# External Services
EXTERNAL_API_URL=https://api.production.com
EXTERNAL_API_KEY=CHANGE_ME_API_KEY
EOF

    print_success "Environment configuration files created"
}

# Function to create application structure
create_app_structure() {
    print_status "Creating application directory structure..."
    
    # Create directories
    mkdir -p app/src
    mkdir -p app/public
    mkdir -p app/tests
    
    # Create basic package.json
    cat > app/package.json << EOF
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "description": "Docker template application",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "lint": "eslint src/",
    "format": "prettier --write src/"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.6.2",
    "eslint": "^8.47.0",
    "prettier": "^3.0.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

    # Create basic Express.js application
    cat > app/src/index.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Ready check endpoint
app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString()
  });
});

// Basic route
app.get('/', (req, res) => {
  res.json({
    message: 'Docker Template Application',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});
EOF

    # Create basic HTML file
    cat > app/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker Template</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .status { padding: 10px; border-radius: 4px; margin: 10px 0; }
        .success { background-color: #d4edda; color: #155724; }
        .info { background-color: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Docker Template Application</h1>
        <div class="status success">
            Application is running successfully!
        </div>
        <div class="status info">
            Ready for development and deployment
        </div>
        <h2>Features</h2>
        <ul>
            <li>Multi-stage Docker builds</li>
            <li>Docker Compose orchestration</li>
            <li>Health checks and monitoring</li>
            <li>Security scanning</li>
            <li>CI/CD integration</li>
        </ul>
        <h2>Endpoints</h2>
        <ul>
            <li><a href="/health">/health</a> - Health check</li>
            <li><a href="/ready">/ready</a> - Ready check</li>
        </ul>
    </div>
</body>
</html>
EOF

    print_success "Application structure created"
}

# Function to create configuration files
create_config_files() {
    print_status "Creating configuration files..."
    
    # Create nginx configuration
    mkdir -p config/nginx
    cat > config/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Security
    server_tokens off;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

    cat > config/nginx/default.conf << 'EOF'
upstream app {
    server app:3000;
}

server {
    listen 80;
    server_name localhost;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Health check endpoint
    location /health {
        proxy_pass http://app/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location /static/ {
        alias /usr/share/nginx/html/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Proxy to application
    location / {
        proxy_pass http://app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF

    # Create PostgreSQL initialization
    mkdir -p config/postgres
    cat > config/postgres/init.sql << 'EOF'
-- Production database initialization
\echo 'Creating database schema...'

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create application schema
CREATE SCHEMA IF NOT EXISTS app;

-- Create basic tables (example)
CREATE TABLE IF NOT EXISTS app.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON app.users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON app.users(created_at);

\echo 'Database initialization completed.'
EOF

    cat > config/postgres/init-dev.sql << 'EOF'
-- Development database initialization
\echo 'Creating development database schema...'

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create application schema
CREATE SCHEMA IF NOT EXISTS app;

-- Create basic tables (example)
CREATE TABLE IF NOT EXISTS app.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample data for development
INSERT INTO app.users (email) VALUES 
    ('user1@example.com'),
    ('user2@example.com'),
    ('admin@example.com')
ON CONFLICT (email) DO NOTHING;

\echo 'Development database initialization completed.'
EOF

    # Create Redis configuration
    mkdir -p config/redis
    cat > config/redis/redis.conf << 'EOF'
# Redis production configuration

# Network
bind 0.0.0.0
port 6379
protected-mode yes

# General
daemonize no
pidfile /var/run/redis.pid
loglevel notice
logfile ""

# Memory
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# Append only file
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Security
requirepass ${REDIS_PASSWORD}
EOF

    # Create Prometheus configuration
    mkdir -p config/prometheus
    cat > config/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'app'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres_exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis_exporter:9121']
EOF

    # Create Grafana configuration
    mkdir -p config/grafana/provisioning/datasources
    mkdir -p config/grafana/provisioning/dashboards
    mkdir -p config/grafana/dashboards
    
    cat > config/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    cat > config/grafana/provisioning/dashboards/default.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

    print_success "Configuration files created"
}

# Function to create Kubernetes manifests
create_k8s_manifests() {
    print_status "Creating Kubernetes manifests..."
    
    mkdir -p k8s
    
    # Deployment
    cat > k8s/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${PROJECT_NAME}
  labels:
    app: ${PROJECT_NAME}
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${PROJECT_NAME}
  template:
    metadata:
      labels:
        app: ${PROJECT_NAME}
        version: v1
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: app
        image: harbor.local/library/${PROJECT_NAME}:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        envFrom:
        - secretRef:
            name: ${PROJECT_NAME}-secret
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
---
apiVersion: v1
kind: Secret
metadata:
  name: ${PROJECT_NAME}-secret
type: Opaque
stringData:
  DB_HOST: "postgres-service"
  DB_NAME: "${PROJECT_NAME}"
  DB_USER: "appuser"
  DB_PASSWORD: "CHANGE_ME"
  REDIS_URL: "redis://redis-service:6379"
EOF

    # Service
    cat > k8s/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: ${PROJECT_NAME}-service
  labels:
    app: ${PROJECT_NAME}
spec:
  selector:
    app: ${PROJECT_NAME}
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  type: ClusterIP
EOF

    # Ingress
    cat > k8s/ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${PROJECT_NAME}-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - ${PROJECT_NAME}.example.com
    secretName: ${PROJECT_NAME}-tls
  rules:
  - host: ${PROJECT_NAME}.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${PROJECT_NAME}-service
            port:
              number: 80
EOF

    print_success "Kubernetes manifests created"
}

# Function to create CI/CD workflow
create_cicd_workflow() {
    print_status "Creating CI/CD workflow..."
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml << EOF
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ${DOCKER_REGISTRY:-harbor.example.com}
  IMAGE_NAME: ${PROJECT_NAME}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: app/package-lock.json

    - name: Install dependencies
      working-directory: ./app
      run: npm ci

    - name: Run tests
      working-directory: ./app
      run: npm test

    - name: Run linting
      working-directory: ./app
      run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: \${{ env.REGISTRY }}
        username: \${{ secrets.REGISTRY_USERNAME }}
        password: \${{ secrets.REGISTRY_PASSWORD }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: \${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: \${{ steps.meta.outputs.tags }}
        labels: \${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        platforms: linux/amd64,linux/arm64

  security:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: '\${{ env.REGISTRY }}/\${{ env.IMAGE_NAME }}:sha-\${{ github.sha }}'
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  deploy:
    if: github.ref == 'refs/heads/main'
    needs: [test, build, security]
    runs-on: ubuntu-latest
    environment: production
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Deploy to production
      run: |
        echo "Deploy to production would happen here"
        # Add your deployment commands here
EOF

    print_success "CI/CD workflow created"
}

# Function to create utility scripts
create_utility_scripts() {
    print_status "Creating utility scripts..."
    
    mkdir -p scripts
    
    # Build script
    cat > scripts/build.sh << 'EOF'
#!/bin/bash

# Docker Build Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
IMAGE_NAME=${1:-$(basename "$(pwd)")}
IMAGE_TAG=${2:-"latest"}
DOCKERFILE=${3:-"Dockerfile"}
BUILD_CONTEXT=${4:-"."}

print_status "Building Docker image..."
print_status "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
print_status "Dockerfile: ${DOCKERFILE}"
print_status "Context: ${BUILD_CONTEXT}"

# Build the image
if docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "${DOCKERFILE}" "${BUILD_CONTEXT}"; then
    print_success "Docker image built successfully"
    
    # Show image details
    print_status "Image details:"
    docker images "${IMAGE_NAME}:${IMAGE_TAG}"
    
    # Show image size
    IMAGE_SIZE=$(docker images --format "table {{.Size}}" "${IMAGE_NAME}:${IMAGE_TAG}" | tail -n 1)
    print_status "Image size: ${IMAGE_SIZE}"
    
else
    print_error "Failed to build Docker image"
    exit 1
fi
EOF

    # Deploy script
    cat > scripts/deploy.sh << 'EOF'
#!/bin/bash

# Docker Deploy Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
ENVIRONMENT=${1:-"development"}
COMPOSE_FILE=""

case $ENVIRONMENT in
    "development"|"dev")
        COMPOSE_FILE="docker-compose.dev.yml"
        ;;
    "production"|"prod")
        COMPOSE_FILE="docker-compose.yml"
        ;;
    *)
        print_error "Unknown environment: $ENVIRONMENT"
        echo "Usage: $0 [development|production]"
        exit 1
        ;;
esac

print_status "Deploying to $ENVIRONMENT environment..."
print_status "Using compose file: $COMPOSE_FILE"

# Check if compose file exists
if [[ ! -f $COMPOSE_FILE ]]; then
    print_error "Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose -f "$COMPOSE_FILE" down

# Pull latest images (for production)
if [[ $ENVIRONMENT == "production" || $ENVIRONMENT == "prod" ]]; then
    print_status "Pulling latest images..."
    docker-compose -f "$COMPOSE_FILE" pull
fi

# Build and start containers
print_status "Building and starting containers..."
if docker-compose -f "$COMPOSE_FILE" up -d --build; then
    print_success "Deployment completed successfully"
    
    # Show running containers
    print_status "Running containers:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    # Show logs
    print_status "Recent logs:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=10
    
else
    print_error "Deployment failed"
    print_status "Checking logs for errors..."
    docker-compose -f "$COMPOSE_FILE" logs --tail=20
    exit 1
fi
EOF

    # Security check script
    cat > scripts/security-check.sh << 'EOF'
#!/bin/bash

# Docker Security Check Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
IMAGE_NAME=${1:-$(basename "$(pwd)")}
IMAGE_TAG=${2:-"latest"}
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

print_status "Running security checks for ${FULL_IMAGE}..."

# Check if image exists
if ! docker images "${FULL_IMAGE}" | grep -q "${IMAGE_NAME}"; then
    print_error "Image not found: ${FULL_IMAGE}"
    print_status "Build the image first with: ./scripts/build.sh"
    exit 1
fi

# Hadolint - Dockerfile linting
print_status "Running Hadolint (Dockerfile linting)..."
if command -v hadolint >/dev/null 2>&1; then
    if hadolint Dockerfile; then
        print_success "Hadolint: No issues found"
    else
        print_warning "Hadolint: Issues found in Dockerfile"
    fi
else
    print_warning "Hadolint not found. Install with: scripts/setup.sh"
fi

# Trivy - Vulnerability scanning
print_status "Running Trivy (Vulnerability scanning)..."
if command -v trivy >/dev/null 2>&1; then
    if trivy image --severity HIGH,CRITICAL "${FULL_IMAGE}"; then
        print_success "Trivy: No high/critical vulnerabilities found"
    else
        print_warning "Trivy: Vulnerabilities found"
    fi
    
    # Generate JSON report
    print_status "Generating Trivy JSON report..."
    trivy image --format json --output trivy-report.json "${FULL_IMAGE}"
    print_status "Report saved to: trivy-report.json"
else
    print_warning "Trivy not found. Install with: scripts/setup.sh"
fi

# Docker Bench Security (if available)
print_status "Checking Docker Bench Security..."
if docker images | grep -q "docker/docker-bench-security"; then
    print_status "Running Docker Bench Security..."
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
else
    print_status "Docker Bench Security not available. Pull with:"
    print_status "docker pull docker/docker-bench-security"
fi

# Image analysis with dive (if available)
print_status "Analyzing image layers..."
if command -v dive >/dev/null 2>&1; then
    print_status "Running dive analysis..."
    dive "${FULL_IMAGE}" --ci
else
    print_warning "dive not found. Install with: scripts/setup.sh"
fi

print_success "Security checks completed"
EOF

    # Clean script
    cat > scripts/clean.sh << 'EOF'
#!/bin/bash

# Docker Clean Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

CLEAN_TYPE=${1:-"containers"}

case $CLEAN_TYPE in
    "containers"|"c")
        print_status "Cleaning containers..."
        docker-compose down --remove-orphans
        docker container prune -f
        ;;
    "images"|"i")
        print_status "Cleaning images..."
        docker image prune -f
        ;;
    "volumes"|"v")
        print_status "Cleaning volumes..."
        docker volume prune -f
        ;;
    "networks"|"n")
        print_status "Cleaning networks..."
        docker network prune -f
        ;;
    "all"|"a")
        print_status "Cleaning everything..."
        docker-compose down --remove-orphans
        docker system prune -a -f --volumes
        ;;
    *)
        echo "Usage: $0 [containers|images|volumes|networks|all]"
        echo "  containers (c) - Remove containers"
        echo "  images (i)     - Remove unused images"
        echo "  volumes (v)    - Remove unused volumes"
        echo "  networks (n)   - Remove unused networks"
        echo "  all (a)        - Remove everything"
        exit 1
        ;;
esac

print_success "Cleanup completed"
EOF

    # Setup CI/CD script
    cat > scripts/setup-cicd.sh << 'EOF'
#!/bin/bash

# CI/CD Setup Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Setting up CI/CD integration..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Initialize git first:"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m 'Initial commit'"
    exit 1
fi

# Check if GitHub CLI is available
if command -v gh >/dev/null 2>&1; then
    print_status "GitHub CLI found. Setting up repository secrets..."
    
    # Set repository secrets
    print_status "Setting up GitHub repository secrets..."
    echo "Please enter your Docker registry credentials:"
    
    read -p "Registry URL (default: harbor.local): " REGISTRY_URL
    REGISTRY_URL=${REGISTRY_URL:-harbor.local}
    read -p "Registry Username: " REGISTRY_USERNAME
    read -s -p "Registry Password: " REGISTRY_PASSWORD
    echo
    
    # Set secrets
    gh secret set REGISTRY_USERNAME --body "$REGISTRY_USERNAME"
    gh secret set REGISTRY_PASSWORD --body "$REGISTRY_PASSWORD"
    
    if [[ -n "$REGISTRY_URL" ]]; then
        gh secret set REGISTRY_URL --body "$REGISTRY_URL"
    fi
    
    print_success "GitHub secrets configured"
    
else
    print_warning "GitHub CLI not found. Manual secret setup required:"
    echo "1. Go to your repository settings"
    echo "2. Navigate to Secrets and variables > Actions"
    echo "3. Add the following secrets:"
    echo "   - REGISTRY_USERNAME: Your registry username"
    echo "   - REGISTRY_PASSWORD: Your registry password"
    echo "   - REGISTRY_URL: Your registry URL (optional)"
fi

# Configure Git hooks (if pre-commit is available)
if command -v pre-commit >/dev/null 2>&1; then
    print_status "Setting up pre-commit hooks..."
    
    cat > .pre-commit-config.yaml << 'EOFPC'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
  
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
        args: ['--ignore', 'DL3008', '--ignore', 'DL3009']

  - repo: https://github.com/aquasecurity/trivy
    rev: v0.44.0
    hooks:
      - id: trivy-docker
        args: ['--exit-code', '1', '--severity', 'HIGH,CRITICAL']
EOFPC

    pre-commit install
    print_success "Pre-commit hooks installed"
else
    print_warning "pre-commit not found. Install with: pip install pre-commit"
fi

print_success "CI/CD setup completed"
print_status "Next steps:"
echo "1. Commit and push your changes"
echo "2. Create a pull request to test the workflow"
echo "3. Configure deployment secrets for production"
EOF

    # Make scripts executable
    chmod +x scripts/*.sh
    
    print_success "Utility scripts created and made executable"
}

# Function to create .gitignore
create_gitignore() {
    print_status "Creating .gitignore file..."
    
    cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.*.local
.env.prod

# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# next.js build output
.next

# nuxt.js build output
.nuxt

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Docker
.dockerignore

# Security scan reports
trivy-report.json
security-report.html

# Backup files
*.backup
*.bak

# Temporary files
tmp/
temp/
*.tmp

# SSL certificates
*.key
*.pem
*.crt
certs/

# Database files
*.sqlite
*.db

# Build artifacts
dist/
build/
target/

# Test artifacts
test-results/
coverage/

# Monitoring data
grafana_data/
prometheus_data/

# Local development overrides
docker-compose.override.local.yml
EOF

    print_success ".gitignore file created"
}

# Function to display summary
display_summary() {
    print_success "Docker template setup completed!"
    echo
    echo "Project structure:"
    echo "  app/                    - Application source code"
    echo "  config/                - Configuration files"
    echo "  scripts/               - Utility scripts"
    echo "  k8s/                   - Kubernetes manifests"
    echo "  .github/workflows/     - CI/CD workflows"
    echo "  Dockerfile             - Production image"
    echo "  Dockerfile.dev         - Development image"
    echo "  docker-compose.yml     - Production orchestration"
    echo "  docker-compose.dev.yml - Development orchestration"
    echo
    echo "Quick start:"
    echo "  1. Update environment variables:"
    echo "     cp .env.example .env && edit .env"
    echo
    echo "  2. Start development environment:"
    echo "     docker-compose -f docker-compose.dev.yml up"
    echo
    echo "  3. Build production image:"
    echo "     ./scripts/build.sh"
    echo
    echo "  4. Run security checks:"
    echo "     ./scripts/security-check.sh"
    echo
    echo "  5. Deploy to production:"
    echo "     ./scripts/deploy.sh production"
    echo
    echo "Available scripts:"
    echo "  ./scripts/setup.sh         - Project initialization"
    echo "  ./scripts/build.sh         - Build Docker images"
    echo "  ./scripts/deploy.sh        - Deploy containers"
    echo "  ./scripts/security-check.sh - Security scanning"
    echo "  ./scripts/clean.sh         - Cleanup containers"
    echo "  ./scripts/setup-cicd.sh    - CI/CD configuration"
    echo
    echo "Access points (after starting dev environment):"
    echo "  Application:     http://localhost:3000"
    echo "  Database Admin:  http://localhost:8080"
    echo "  Redis Commander: http://localhost:8081"
    echo "  Grafana:         http://localhost:3001"
    echo "  Prometheus:      http://localhost:9090"
    echo
    print_warning "Remember to:"
    echo "  - Update .env with your actual configuration"
    echo "  - Change default passwords in production"
    echo "  - Configure your Docker registry in CI/CD"
    echo "  - Review and customize Kubernetes manifests"
    echo
    print_success "Happy containerizing!"
}

# Main execution
main() {
    echo "Docker Template Setup"
    echo "====================="
    echo
    
    # Run setup steps
    check_docker
    install_optional_tools
    create_env_files
    create_app_structure
    create_config_files
    create_k8s_manifests
    create_cicd_workflow
    create_utility_scripts
    create_gitignore
    
    # Display summary
    display_summary
}

# Run main function
main "$@"