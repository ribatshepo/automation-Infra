#!/bin/bash

# Template Generation Script
# Generates actual files from templates using configuration

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

# Configuration file
CONFIG_FILE=${1:-"template.config"}

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    if [[ -f "template.config.example" ]]; then
        print_status "Creating config file from example..."
        cp template.config.example "$CONFIG_FILE"
        print_warning "Please edit $CONFIG_FILE with your project-specific values"
        exit 0
    else
        print_error "Configuration file not found: $CONFIG_FILE"
        print_status "Create a config file from template.config.example"
        exit 1
    fi
fi

print_status "Loading configuration from $CONFIG_FILE..."

# Source configuration
source "$CONFIG_FILE"

# Function to substitute templates
substitute_template() {
    local template_file=$1
    local output_file=$2
    
    print_status "Generating $output_file from $template_file..."
    
    if [[ ! -f "$template_file" ]]; then
        print_error "Template file not found: $template_file"
        return 1
    fi
    
    # Read template and substitute variables
    local content=$(cat "$template_file")
    
    # Substitute all variables from config
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        # Remove quotes from value if present
        value=$(echo "$value" | sed 's/^["'\'']\|["'\'']$//g')
        
        # Substitute in content
        content=${content//\{\{$key\}\}/$value}
    done < "$CONFIG_FILE"
    
    # Write output file
    echo "$content" > "$output_file"
    print_success "Generated $output_file"
}

# Function to generate Docker Compose files
generate_compose_files() {
    print_status "Generating Docker Compose files..."
    
    # Production compose
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    # For production, use Harbor registry image:
    # image: ${HARBOR_URL}/${HARBOR_PROJECT}/${APP_NAME}:latest
    container_name: ${APP_NAME}-prod
    ports:
      - "\${PORT:-${APP_PORT}}:${APP_PORT}"
    environment:
      - ${ENV_VAR_NAME}=production
      - PORT=${APP_PORT}
      - DB_HOST=db
      - DB_NAME=\${DB_NAME:-${APP_NAME}}
      - DB_USER=\${DB_USER:-${APP_USER}}
      - DB_PASSWORD=\${DB_PASSWORD}
      - CACHE_URL=${CACHE_TYPE}://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${APP_PORT}/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: ${DB_IMAGE}
    container_name: ${DB_TYPE}-prod
    environment:
      POSTGRES_DB: \${DB_NAME:-${APP_NAME}}
      POSTGRES_USER: \${DB_USER:-${APP_USER}}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ${DB_TYPE}_data:/var/lib/postgresql/data
      - ./config/${DB_TYPE}/${DB_INIT_SCRIPT}:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER:-${APP_USER}} -d \${DB_NAME:-${APP_NAME}}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    restart: unless-stopped
    networks:
      - app-network

  cache:
    image: ${CACHE_IMAGE}
    container_name: ${CACHE_TYPE}-prod
    command: ${CACHE_TYPE}-server --appendonly yes --requirepass \${CACHE_PASSWORD:-}
    volumes:
      - ${CACHE_TYPE}_data:/data
    healthcheck:
      test: ["CMD", "${CACHE_TYPE}-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 30s
    restart: unless-stopped
    networks:
      - app-network

EOF

    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        cat >> docker-compose.yml << EOF
  prometheus:
    image: ${PROMETHEUS_IMAGE}
    container_name: prometheus
    volumes:
      - ./config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - app-network
    restart: unless-stopped

  grafana:
    image: ${GRAFANA_IMAGE}
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_USER=\${GRAFANA_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=\${GRAFANA_PASSWORD:-admin}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./config/grafana/provisioning:/etc/grafana/provisioning:ro
    ports:
      - "3001:3000"
    networks:
      - app-network
    restart: unless-stopped

EOF
    fi

    cat >> docker-compose.yml << EOF
volumes:
  ${DB_TYPE}_data:
    driver: local
  ${CACHE_TYPE}_data:
    driver: local
EOF

    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        cat >> docker-compose.yml << EOF
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
EOF
    fi

    cat >> docker-compose.yml << EOF

networks:
  app-network:
    driver: bridge
EOF

    print_success "Generated docker-compose.yml"
    
    # Development compose
    cat > docker-compose.dev.yml << EOF
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    container_name: ${APP_NAME}-dev
    ports:
      - "\${PORT:-${APP_PORT}}:${APP_PORT}"
    environment:
      - ${ENV_VAR_NAME}=${DEV_ENV_VALUE}
      - PORT=${APP_PORT}
      - DB_HOST=db
      - DB_NAME=\${DB_NAME:-${APP_NAME}_dev}
      - DB_USER=\${DB_USER:-devuser}
      - DB_PASSWORD=\${DB_PASSWORD:-devpass}
      - CACHE_URL=${CACHE_TYPE}://cache:6379
    volumes:
      - .:/app
      - /app/${DEPENDENCIES_PATH}
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    networks:
      - dev-network
    stdin_open: true
    tty: true

  db:
    image: ${DB_IMAGE}
    container_name: ${DB_TYPE}-dev
    environment:
      POSTGRES_DB: \${DB_NAME:-${APP_NAME}_dev}
      POSTGRES_USER: \${DB_USER:-devuser}
      POSTGRES_PASSWORD: \${DB_PASSWORD:-devpass}
    ports:
      - "5432:5432"
    volumes:
      - ${DB_TYPE}_dev_data:/var/lib/postgresql/data
      - ./config/${DB_TYPE}/${DB_DEV_INIT_SCRIPT}:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER:-devuser} -d \${DB_NAME:-${APP_NAME}_dev}"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - dev-network

  cache:
    image: ${CACHE_IMAGE}
    container_name: ${CACHE_TYPE}-dev
    command: ${CACHE_TYPE}-server --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - ${CACHE_TYPE}_dev_data:/data
    healthcheck:
      test: ["CMD", "${CACHE_TYPE}-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - dev-network

  adminer:
    image: adminer:4.8.1
    container_name: adminer-dev
    ports:
      - "8080:8080"
    environment:
      ADMINER_DEFAULT_SERVER: db
    depends_on:
      - db
    networks:
      - dev-network

volumes:
  ${DB_TYPE}_dev_data:
    driver: local
  ${CACHE_TYPE}_dev_data:
    driver: local

networks:
  dev-network:
    driver: bridge
EOF

    print_success "Generated docker-compose.dev.yml"
}

# Function to generate Kubernetes manifests
generate_k8s_manifests() {
    print_status "Generating Kubernetes manifests..."
    
    mkdir -p k8s
    
    # Deployment
    cat > k8s/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  labels:
    app: ${APP_NAME}
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
        version: v1
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: app
        image: ${HARBOR_URL}/${HARBOR_PROJECT}/${APP_NAME}:latest
        imagePullPolicy: Always
        ports:
        - containerPort: ${APP_PORT}
          name: http
        env:
        - name: ${ENV_VAR_NAME}
          value: "production"
        - name: PORT
          value: "${APP_PORT}"
        envFrom:
        - secretRef:
            name: ${APP_NAME}-secret
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
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
  name: ${APP_NAME}-secret
type: Opaque
stringData:
  DB_HOST: "${DB_TYPE}-service"
  DB_NAME: "${APP_NAME}"
  DB_USER: "${APP_USER}"
  DB_PASSWORD: "CHANGE_ME"
  CACHE_URL: "${CACHE_TYPE}://${CACHE_TYPE}-service:6379"
EOF

    # Service
    cat > k8s/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-service
  labels:
    app: ${APP_NAME}
spec:
  selector:
    app: ${APP_NAME}
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
  name: ${APP_NAME}-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - ${APP_NAME}.example.com
    secretName: ${APP_NAME}-tls
  rules:
  - host: ${APP_NAME}.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${APP_NAME}-service
            port:
              number: 80
EOF

    print_success "Generated Kubernetes manifests"
}

# Function to update scripts with config values
update_scripts() {
    print_status "Updating scripts with configuration values..."
    
    # Update variables in scripts
    local scripts=(
        "scripts/build.sh"
        "scripts/deploy.sh" 
        "scripts/harbor.sh"
        "scripts/setup-cicd.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            # Update default values in scripts
            sed -i "s/IMAGE_NAME=\${1:-\$(basename \"\$(pwd)\")}/IMAGE_NAME=\${1:-${APP_NAME}}/g" "$script"
            sed -i "s/HARBOR_URL=\${HARBOR_URL:-\"harbor.local\"}/HARBOR_URL=\${HARBOR_URL:-\"${HARBOR_URL}\"}/g" "$script"
            sed -i "s/HARBOR_PROJECT=\${HARBOR_PROJECT:-\"library\"}/HARBOR_PROJECT=\${HARBOR_PROJECT:-\"${HARBOR_PROJECT}\"}/g" "$script"
            sed -i "s/PORT:-3000/PORT:-${APP_PORT}/g" "$script"
            print_success "Updated $script"
        fi
    done
}

# Main execution
main() {
    print_status "Generating Docker template files from configuration..."
    
    # Generate Dockerfiles
    substitute_template "Dockerfile.template" "Dockerfile"
    substitute_template "Dockerfile.dev.template" "Dockerfile.dev"
    
    # Generate compose files
    generate_compose_files
    
    # Generate Kubernetes manifests
    generate_k8s_manifests
    
    # Update scripts
    update_scripts
    
    print_success "Template generation completed!"
    print_status "Files generated:"
    echo "  - Dockerfile"
    echo "  - Dockerfile.dev"
    echo "  - docker-compose.yml"
    echo "  - docker-compose.dev.yml"
    echo "  - k8s/deployment.yaml"
    echo "  - k8s/service.yaml"
    echo "  - k8s/ingress.yaml"
    echo ""
    print_warning "Next steps:"
    echo "1. Review generated files"
    echo "2. Update configuration in $CONFIG_FILE if needed"
    echo "3. Run './scripts/setup.sh' to initialize the project"
    echo "4. Build and test: 'make build && make up'"
}

# Run main function
main "$@"