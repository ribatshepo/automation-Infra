# Template Usage Examples

This document provides examples of how to configure the Docker template for different types of applications.

## Node.js Application Example

```bash
# template.config
BASE_IMAGE=node
BASE_IMAGE_TAG=18.17.0-alpine3.18
APP_NAME=my-node-app
APP_PORT=3000
PACKAGE_FILES=package*.json
DEPENDENCIES_PATH=node_modules
INSTALL_DEPENDENCIES_COMMAND=npm ci --only=production
INSTALL_ALL_DEPENDENCIES=npm install
BUILD_COMMAND=npm run build
START_COMMAND=["npm", "start"]
DEV_START_COMMAND=["npm", "run", "dev"]
ENV_VAR_NAME=NODE_ENV
DEV_ENV_VALUE=development
HEALTH_CHECK_COMMAND=curl -f http://localhost:${PORT:-3000}/health || exit 1
```

## Python Application Example

```bash
# template.config
BASE_IMAGE=python
BASE_IMAGE_TAG=3.11-alpine
APP_NAME=my-python-app
APP_PORT=8000
PACKAGE_FILES=requirements.txt
DEPENDENCIES_PATH=.venv
INSTALL_DEPENDENCIES_COMMAND=pip install --no-cache-dir -r requirements.txt
INSTALL_ALL_DEPENDENCIES=pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt
BUILD_COMMAND=echo "No build needed"
START_COMMAND=["python", "app.py"]
DEV_START_COMMAND=["python", "app.py", "--reload"]
ENV_VAR_NAME=ENVIRONMENT
DEV_ENV_VALUE=development
HEALTH_CHECK_COMMAND=curl -f http://localhost:${PORT:-8000}/health || exit 1
UPDATE_PACKAGES_COMMAND=apk update && apk upgrade
INSTALL_RUNTIME_DEPS=apk add --no-cache curl
INSTALL_DEV_TOOLS=apk add --no-cache curl git bash
CLEANUP_COMMAND=rm -rf /var/cache/apk/*
```

## Go Application Example

```bash
# template.config
BASE_IMAGE=golang
BASE_IMAGE_TAG=1.21-alpine
APP_NAME=my-go-app
APP_PORT=8080
PACKAGE_FILES=go.mod go.sum
DEPENDENCIES_PATH=vendor
INSTALL_DEPENDENCIES_COMMAND=go mod download
INSTALL_ALL_DEPENDENCIES=go mod download
BUILD_COMMAND=CGO_ENABLED=0 GOOS=linux go build -o main .
BUILD_OUTPUT_PATH=.
START_COMMAND=["./main"]
DEV_START_COMMAND=["go", "run", "."]
ENV_VAR_NAME=ENVIRONMENT
DEV_ENV_VALUE=development
HEALTH_CHECK_COMMAND=curl -f http://localhost:${PORT:-8080}/health || exit 1

# Use minimal runtime image
RUNTIME_IMAGE=alpine:latest
```

## Java Spring Boot Example

```bash
# template.config
BASE_IMAGE=openjdk
BASE_IMAGE_TAG=17-jdk-alpine
APP_NAME=my-spring-app
APP_PORT=8080
PACKAGE_FILES=pom.xml
DEPENDENCIES_PATH=target/dependency
INSTALL_DEPENDENCIES_COMMAND=mvn dependency:copy-dependencies
INSTALL_ALL_DEPENDENCIES=mvn dependency:resolve
BUILD_COMMAND=mvn package -DskipTests
BUILD_OUTPUT_PATH=target
START_COMMAND=["java", "-jar", "target/app.jar"]
DEV_START_COMMAND=["mvn", "spring-boot:run"]
ENV_VAR_NAME=SPRING_PROFILES_ACTIVE
DEV_ENV_VALUE=development
HEALTH_CHECK_COMMAND=curl -f http://localhost:${PORT:-8080}/actuator/health || exit 1
```

## .NET Application Example

```bash
# template.config
BASE_IMAGE=mcr.microsoft.com/dotnet/sdk
BASE_IMAGE_TAG=8.0-alpine
APP_NAME=my-dotnet-app
APP_PORT=5000
PACKAGE_FILES=*.csproj
DEPENDENCIES_PATH=bin/Release
INSTALL_DEPENDENCIES_COMMAND=dotnet restore
INSTALL_ALL_DEPENDENCIES=dotnet restore
BUILD_COMMAND=dotnet publish -c Release -o out
BUILD_OUTPUT_PATH=out
START_COMMAND=["dotnet", "MyApp.dll"]
DEV_START_COMMAND=["dotnet", "run"]
ENV_VAR_NAME=ASPNETCORE_ENVIRONMENT
DEV_ENV_VALUE=Development
HEALTH_CHECK_COMMAND=curl -f http://localhost:${PORT:-5000}/health || exit 1

# Use runtime image for production
RUNTIME_IMAGE=mcr.microsoft.com/dotnet/aspnet
RUNTIME_IMAGE_TAG=8.0-alpine
```

## Rust Application Example

```bash
# template.config
BASE_IMAGE=rust
BASE_IMAGE_TAG=1.75-alpine
APP_NAME=my-rust-app
APP_PORT=3000
PACKAGE_FILES=Cargo.toml Cargo.lock
DEPENDENCIES_PATH=target/release
INSTALL_DEPENDENCIES_COMMAND=cargo fetch
INSTALL_ALL_DEPENDENCIES=cargo fetch
BUILD_COMMAND=cargo build --release
BUILD_OUTPUT_PATH=target/release
START_COMMAND=["./my-rust-app"]
DEV_START_COMMAND=["cargo", "run"]
ENV_VAR_NAME=RUST_ENV
DEV_ENV_VALUE=development
HEALTH_CHECK_COMMAND=curl -f http://localhost:${PORT:-3000}/health || exit 1
```

## Multi-Database Configuration

```bash
# template.config with multiple databases
DB_TYPE=postgres
DB_IMAGE=postgres:15.4-alpine

# Additional database
MONGODB_ENABLED=true
MONGODB_IMAGE=mongo:7.0

# Cache
CACHE_TYPE=redis
CACHE_IMAGE=redis:7.2.1-alpine

# Search engine
ELASTICSEARCH_ENABLED=true
ELASTICSEARCH_IMAGE=elasticsearch:8.11.0
```

## Custom Harbor Configuration

```bash
# template.config for enterprise Harbor setup
HARBOR_URL=harbor.company.com
HARBOR_PROJECT=my-team
HARBOR_REGISTRY_USERNAME=service-account
HARBOR_SCAN_ON_PUSH=true
HARBOR_VULNERABILITY_THRESHOLD=high
```

## Microservice Configuration

```bash
# template.config for microservice
APP_NAME=user-service
APP_PORT=3001
BASE_IMAGE=node
BASE_IMAGE_TAG=18-alpine

# Service mesh integration
ISTIO_ENABLED=true
JAEGER_ENABLED=true
PROMETHEUS_ENABLED=true

# Database per service
DB_TYPE=postgres
DB_NAME=user_service_db
CACHE_TYPE=redis
```

## Development vs Production Differences

### Development Configuration
```bash
# Development overrides
DEV_MOUNT_SOURCE=true
DEV_ENABLE_DEBUGGER=true
DEV_HOT_RELOAD=true
DEV_ENABLE_ADMIN_TOOLS=true
DEV_LOG_LEVEL=debug
```

### Production Configuration
```bash
# Production settings
PROD_MULTI_STAGE=true
PROD_MINIMAL_IMAGE=true
PROD_SECURITY_SCANNING=true
PROD_RESOURCE_LIMITS=true
PROD_HEALTH_CHECKS=true
PROD_LOG_LEVEL=info
```

## Usage

1. Choose an example configuration above
2. Copy the relevant `template.config` settings
3. Customize values for your specific application
4. Run `./scripts/generate.sh` to create your files
5. Run `./scripts/setup.sh` to initialize the project

## Advanced Customization

You can extend the template system by:

1. Adding new template variables in `template.config.example`
2. Updating `scripts/generate.sh` to handle new variables
3. Creating additional template files (`.template` extension)
4. Modifying the substitution logic for complex transformations