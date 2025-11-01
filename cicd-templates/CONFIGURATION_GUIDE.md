# Configuration Guide for Dynamic CI/CD Workflows

This guide shows how to configure workflows without hardcoding values, making them reusable across different projects and environments.

## The Problem with Hardcoding

###  Bad Examples (Hardcoded):
```yaml
# Hardcoded application name
app-name: 'my-app'

# Hardcoded domain
ingress-host: 'api.example.com'

# Hardcoded resource values
resource-requests-memory: '256Mi'

# Hardcoded workflow paths
uses: ./.github/workflows/docker.yml

# Hardcoded environment values
NODE_ENV: 'production'
```

###  Good Examples (Dynamic):
```yaml
# Dynamic application name
app-name: ${{ github.event.inputs.app_name || github.event.repository.name }}

# Dynamic domain with configurable suffix
ingress-host: ${{ env.APP_NAME }}.${{ vars.DOMAIN_SUFFIX || 'example.com' }}

# Configurable resource values
resource-requests-memory: ${{ vars.MEMORY_REQUEST || '256Mi' }}

# Remote workflow reference
uses: github-user/repo/.github/workflows/docker.yml@main

# Environment-based values
NODE_ENV: ${{ env.ENVIRONMENT == 'prod' && 'production' || 'development' }}
```

## Configuration Layers

### 1. GitHub Repository Variables
Set these at organization or repository level:

```bash
# Domain configuration
DOMAIN_SUFFIX=yourdomain.com

# Application configuration
APP_PORT=8080
HEALTH_CHECK_PATH=/health
API_HEALTH_PATH=/api/health

# Resource configuration per environment
DEV_REPLICAS=1
STAGING_REPLICAS=2
PROD_REPLICAS=5

DEV_MEMORY_REQUEST=128Mi
STAGING_MEMORY_REQUEST=256Mi
PROD_MEMORY_REQUEST=512Mi

DEV_CPU_REQUEST=100m
STAGING_CPU_REQUEST=250m
PROD_CPU_REQUEST=500m

# Feature flags
AUTOSCALING_ENABLED=true
INGRESS_ENABLED=true
MONITORING_ENABLED=true
METRICS_ENABLED=true

# Timeout configurations
DEPLOY_TIMEOUT=10
REQUEST_TIMEOUT=30

# Connection limits
STAGING_MAX_CONN=100
PROD_MAX_CONN=1000
```

### 2. GitHub Secrets
Sensitive information only:

```bash
# Registry credentials
HARBOR_REGISTRY=harbor.yourdomain.com
HARBOR_USERNAME=username
HARBOR_PASSWORD=token
HARBOR_PROJECT=project-name

# Kubernetes credentials
KUBECONFIG=<base64-kubeconfig>
DEV_KUBECONFIG=<base64-dev-kubeconfig>
STAGING_KUBECONFIG=<base64-staging-kubeconfig>

# Database connections
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
```

### 3. Workflow Inputs
User-configurable at runtime:

```yaml
workflow_dispatch:
  inputs:
    app_name:
      description: 'Application name (defaults to repository name)'
      required: false
      type: string
    
    environment:
      description: 'Target environment'
      required: true
      default: 'dev'
      type: choice
      options: [dev, staging, prod]
    
    image_tag:
      description: 'Image tag (defaults to commit SHA)'
      required: false
      type: string
    
    domain_suffix:
      description: 'Domain suffix for ingress'
      required: false
      type: string
    
    helm_chart_path:
      description: 'Path to Helm chart'
      required: false
      default: './helm-charts/app-template'
      type: string
```

### 4. Environment Variables
Computed values:

```yaml
env:
  # Dynamic values based on inputs and context
  APP_NAME: ${{ github.event.inputs.app_name || github.event.repository.name }}
  IMAGE_TAG: ${{ github.event.inputs.image_tag || github.sha }}
  ENVIRONMENT: ${{ github.event.inputs.environment || (github.ref == 'refs/heads/main' && 'prod' || 'dev') }}
  DOMAIN_SUFFIX: ${{ github.event.inputs.domain_suffix || vars.DOMAIN_SUFFIX || 'example.com' }}
  NAMESPACE: ${{ vars.NAMESPACE_PREFIX }}${{ env.ENVIRONMENT }}
```

## Dynamic Workflow References

### Remote Workflow References
Instead of relative paths, use repository references:

```yaml
#  Good - Remote reference with version
uses: github-user/repo/.github/workflows/docker.yml@main

#  Good - Remote reference with specific tag
uses: github-user/repo/.github/workflows/docker.yml@v1.0.0

#  Bad - Relative path (only works within same repo)
uses: ./.github/workflows/docker.yml
```

### Template Workflow
```yaml
name: 'Configurable Deployment Template'

on:
  workflow_call:
    inputs:
      # Required inputs
      environment:
        required: true
        type: string
      image_url:
        required: true
        type: string
      
      # Optional inputs with defaults
      app_name:
        required: false
        default: ${{ github.event.repository.name }}
        type: string
      namespace:
        required: false
        default: ${{ inputs.environment }}
        type: string
      replicas:
        required: false
        default: 1
        type: number
      
    secrets:
      # Required secrets
      KUBECONFIG:
        required: true
      HARBOR_USERNAME:
        required: true
      HARBOR_PASSWORD:
        required: true
```

## Environment-Specific Configuration

### Using Conditional Values
```yaml
# Resource allocation based on environment
resources:
  requests:
    memory: ${{ 
      (inputs.environment == 'prod' && (vars.PROD_MEMORY_REQUEST || '512Mi')) ||
      (inputs.environment == 'staging' && (vars.STAGING_MEMORY_REQUEST || '256Mi')) ||
      (vars.DEV_MEMORY_REQUEST || '128Mi')
    }}
    cpu: ${{ 
      (inputs.environment == 'prod' && (vars.PROD_CPU_REQUEST || '500m')) ||
      (inputs.environment == 'staging' && (vars.STAGING_CPU_REQUEST || '250m')) ||
      (vars.DEV_CPU_REQUEST || '100m')
    }}

# Replicas based on environment
replicas: ${{ 
  (inputs.environment == 'prod' && (vars.PROD_REPLICAS || 5)) ||
  (inputs.environment == 'staging' && (vars.STAGING_REPLICAS || 2)) ||
  (vars.DEV_REPLICAS || 1)
}}

# Dynamic hostnames
ingress:
  hosts:
    - host: ${{ 
        (inputs.environment == 'prod' && format('{0}.{1}', inputs.app_name, vars.DOMAIN_SUFFIX)) ||
        (format('{0}-{1}.{2}', inputs.environment, inputs.app_name, vars.DOMAIN_SUFFIX))
      }}
```

### Values Files per Environment
Create separate values files:

```yaml
# helm/values-dev.yaml
resources:
  requests:
    memory: 128Mi
    cpu: 100m
replicas: 1

# helm/values-staging.yaml  
resources:
  requests:
    memory: 256Mi
    cpu: 250m
replicas: 2

# helm/values-prod.yaml
resources:
  requests:
    memory: 512Mi
    cpu: 500m
replicas: 5
```

Then reference dynamically:
```yaml
values-file: ./helm/values-${{ inputs.environment }}.yaml
```

## Best Practices

### 1. Use GitHub Variables for Configuration
```bash
# Set at repository level
gh variable set DOMAIN_SUFFIX --body "yourdomain.com"
gh variable set APP_PORT --body "8080"
gh variable set PROD_REPLICAS --body "5"
```

### 2. Provide Sensible Defaults
```yaml
port: ${{ vars.APP_PORT || 8080 }}
health-check-path: ${{ vars.HEALTH_CHECK_PATH || '/health' }}
```

### 3. Make Resource Limits Configurable
```yaml
resource-limits-memory: ${{ 
  vars[format('{0}_MEMORY_LIMIT', upper(inputs.environment))] || 
  (inputs.environment == 'prod' && '1Gi' || '512Mi') 
}}
```

### 4. Use Repository Context
```yaml
# Get repository name dynamically
app_name: ${{ github.event.repository.name }}

# Get organization name
registry_prefix: ${{ github.repository_owner }}

# Get branch-based environment
environment: ${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}
```

### 5. Validate Required Variables
```yaml
- name: 'Validate configuration'
  run: |
    if [[ -z "${{ vars.DOMAIN_SUFFIX }}" ]]; then
      echo "::error::DOMAIN_SUFFIX variable is required"
      exit 1
    fi
    
    if [[ -z "${{ secrets.HARBOR_REGISTRY }}" ]]; then
      echo "::error::HARBOR_REGISTRY secret is required"
      exit 1
    fi
```

## Migration from Hardcoded to Dynamic

### Step 1: Identify Hardcoded Values
```bash
# Find hardcoded domains
grep -r "\.example\.com" .github/

# Find hardcoded app names
grep -r "app-name:" .github/

# Find hardcoded resource values
grep -r "256Mi\|512Mi\|1Gi" .github/
```

### Step 2: Extract to Variables
```bash
# Replace hardcoded values with variables
sed -i 's/example\.com/${{ vars.DOMAIN_SUFFIX || '\''example.com'\'' }}/g' .github/workflows/*.yml
```

### Step 3: Update Workflow Calls
```yaml
# Before
uses: ./.github/workflows/docker.yml

# After  
uses: your-org/ci-cd-templates/.github/workflows/docker.yml@main
```

### Step 4: Test with Different Configurations
```bash
# Test with different app names
gh workflow run deploy.yml -f app_name=test-app -f environment=dev

# Test with different domains
gh workflow run deploy.yml -f domain_suffix=test.com -f environment=staging
```

This approach makes workflows truly reusable and maintainable across different projects and environments!