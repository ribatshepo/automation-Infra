# Ansible Infrastructure Automation

[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)

A comprehensive Ansible-based infrastructure automation toolkit for deploying and managing containerized services, databases, and CI/CD pipelines.

##  **Overview**

This repository provides production-ready Ansible playbooks and automation scripts for deploying a complete DevOps infrastructure stack including:

- **Container Registry**(Harbor)
- **Artifact Repository**(JFrog Artifactory)
- **Container Orchestration**(Kubernetes)
- **Object Storage**(MinIO)
- **Database Systems**(PostgreSQL, Redis)
- **CI/CD Templates**(GitHub Actions with Harbor + JFrog integration)
- **Virtualization Support**(QEMU Guest Agent)

##  **Infrastructure Components**

###  **Container & Registry Services**
- **[Harbor](./harbor/)**- Enterprise container registry with security scanning
- **[Kubernetes](./kubernetes/)**- Container orchestration platform
- **[QEMU Guest Agent](./qemu-agent/)**- VM integration and management

###  **DevOps & Artifact Management**
- **[JFrog Artifactory](./jfrog/)**- Universal artifact repository manager
- **[Nexus](./nexus/)**- Repository manager (alternative/legacy)
- **[CI/CD Templates](./cicd-templates/)**- GitHub Actions workflows for Harbor + JFrog

###  **Data & Storage Services**
- **[PostgreSQL](./postgres/)**- Relational database system
- **[Redis](./redis/)**- In-memory data structure store
- **[MinIO](./minio/)**- S3-compatible object storage

##  **Quick Start**

### Prerequisites
```bash
# Install Ansible
sudo apt update && sudo apt install ansible -y

# Clone repository
git clone <repository-url>
cd ansible-infra

# Configure inventory
cp inventory.yml.example inventory.yml
# Edit inventory.yml with your server details
```

### Basic Deployment
```bash
# Deploy all services
make deploy-all

# Deploy specific service
make deploy-harbor
make deploy-jfrog
make deploy-postgres

# Verify deployments
make verify-all
```

### Service-Specific Deployment
```bash
# Harbor (Container Registry)
cd harbor && ./deploy-harbor.sh

# JFrog Artifactory (Package Registry)
cd jfrog && ./deploy-artifactory-enhanced.sh

# PostgreSQL Database
cd postgres && ./deploy-postgresql.sh

# Kubernetes Cluster
cd kubernetes && ansible-playbook -i ../inventory.yml install-kubernetes.yml
```

##  **Project Structure**

```
ansible-infra/
├──  README.md                    # This file
├──  ansible.cfg                  # Ansible configuration
├──  inventory.yml                # Infrastructure inventory
├──  Makefile                     # Automation shortcuts
│
├──  harbor/                      # Harbor container registry
│   ├──  deploy-harbor.sh         # Deployment script
│   ├──  install-harbor.yml       # Ansible playbook
│   ├──  vars.yml                 # Configuration variables
│   └──  vault.yml                # Encrypted secrets
│
├──  jfrog/                       # JFrog Artifactory
│   ├──  deploy-artifactory-enhanced.sh
│   ├──  install-artifactory.yml  # Ansible playbook
│   ├──  vars.yml                 # Configuration variables
│   ├──  vault.yml                # Encrypted secrets
│   └──  tasks/                   # Ansible task modules
│
├──  kubernetes/                  # Kubernetes cluster
│   ├──  install-kubernetes.yml   # Cluster setup playbook
│   ├──  vars.yml                 # Cluster configuration
│   └──  vault.yml                # Cluster secrets
│
├──  postgres/                    # PostgreSQL database
│   ├──  deploy-postgresql.sh     # Deployment script
│   ├──  install-postgresql.yml   # Ansible playbook
│   ├──  maintenance-postgresql.yml
│   ├──  verify-postgresql.yml    # Health checks
│   └──  templates/               # Configuration templates
│
├──  redis/                       # Redis data store
│   ├──  install-redis.yml        # Ansible playbook
│   ├──  vars.yml                 # Configuration variables
│   └──  vault.yml                # Encrypted secrets
│
├──  minio/                       # MinIO object storage
│   ├──  install-minio.yml        # Ansible playbook
│   ├──  vars.yml                 # Configuration variables
│   └──  vault.yml                # Encrypted secrets
│
├──  nexus/                       # Nexus repository manager
│   ├──  install-nexus.yml        # Ansible playbook
│   └──  vars.yml                 # Configuration variables
│
├──  qemu-agent/                  # QEMU Guest Agent
│   ├──  deploy-qemu-guest-agent.sh
│   ├──  install-qemu-guest-agent.yml
│   └──  verify-qemu-guest-agent.yml
│
└──  cicd-templates/              # CI/CD automation templates
    ├──  README.md                # CI/CD documentation
    ├──  setup.sh                 # Template integration script
    ├──  configure-secrets.sh     # GitHub secrets configuration
    ├──  validate-secrets.sh      # Secrets validation
    ├──  .github/
    │   ├──  workflows/           # GitHub Actions workflows
    │   │   ├── dotnet.yml          # .NET CI/CD pipeline
    │   │   ├── python.yml          # Python CI/CD pipeline
    │   │   ├── golang.yml          # Go CI/CD pipeline
    │   │   ├── rust.yml            # Rust CI/CD pipeline
    │   │   ├── nodejs.yml          # Node.js CI/CD pipeline
    │   │   └── docker.yml          # Docker CI/CD pipeline
    │   └──  actions/             # Reusable composite actions
    │       ├── harbor-push/        # Harbor container push action
    │       └── artifactory-push/   # Artifactory package push action
    ├──  docs/                    # Comprehensive documentation
    └──  examples/                # Real-world usage examples
```

##  **Configuration**

### Infrastructure Inventory
Edit `inventory.yml` to match your environment:
```yaml
all:
  children:
    docker_hosts:
      hosts:
        server1:
          ansible_host: 10.100.10.215
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### Service Configuration
Each service has its own configuration files:
- `vars.yml` - Service-specific variables
- `vault.yml` - Encrypted secrets (use `ansible-vault`)

### Default Service Endpoints
Based on default configuration:
- **Harbor**: http://10.100.10.215:8080
- **JFrog Artifactory**: http://10.100.10.215:8081
- **MinIO**: http://10.100.10.215:9000
- **PostgreSQL**: 10.100.10.215:5432
- **Redis**: 10.100.10.215:6379

##  **Available Make Targets**

```bash
# Deployment
make deploy-all          # Deploy all services
make deploy-harbor       # Deploy Harbor registry
make deploy-jfrog        # Deploy JFrog Artifactory
make deploy-postgres     # Deploy PostgreSQL
make deploy-redis        # Deploy Redis
make deploy-minio        # Deploy MinIO
make deploy-kubernetes   # Deploy Kubernetes

# Verification
make verify-all          # Verify all services
make verify-harbor       # Verify Harbor
make verify-jfrog        # Verify JFrog
make verify-postgres     # Verify PostgreSQL

# Maintenance
make backup-postgres     # Backup PostgreSQL
make maintenance-all     # Run maintenance tasks

# CI/CD
make setup-cicd          # Setup CI/CD templates
make configure-secrets   # Configure GitHub secrets
```

##  **CI/CD Integration**

The included **[CI/CD Templates](./cicd-templates/)**provide ready-to-use GitHub Actions workflows that integrate with your Harbor and JFrog infrastructure:

### Supported Technologies
- **.NET**- NuGet packages + Docker images
- **Python**- PyPI packages + Docker images  
- **Go**- Go modules + Docker images
- **Rust**- Cargo packages + Docker images
- **Node.js**- npm packages + Docker images
- **Docker**- Container images only

### Quick CI/CD Setup
```bash
# Navigate to your project
cd /path/to/your-project

# Setup CI/CD templates
/path/to/ansible-infra/cicd-templates/setup.sh . --interactive

# Configure GitHub secrets
/path/to/ansible-infra/cicd-templates/configure-secrets.sh --template

# Validate configuration
/path/to/ansible-infra/cicd-templates/validate-secrets.sh
```

##  **Security & Secrets Management**

### Ansible Vault
Sensitive configuration is encrypted using Ansible Vault:
```bash
# Edit encrypted files
ansible-vault edit harbor/vault.yml
ansible-vault edit jfrog/vault.yml

# Encrypt new files
ansible-vault encrypt sensitive-file.yml

# Run playbooks with vault
ansible-playbook -i inventory.yml --ask-vault-pass playbook.yml
```

### GitHub Secrets
For CI/CD integration, configure these GitHub repository secrets:
- `HARBOR_REGISTRY`, `HARBOR_USERNAME`, `HARBOR_PASSWORD`, `HARBOR_PROJECT`
- `ARTIFACTORY_URL`, `ARTIFACTORY_USERNAME`, `ARTIFACTORY_PASSWORD`
- `ARTIFACTORY_*_REPO` (technology-specific repository names)

##  **Testing & Verification**

### Service Health Checks
```bash
# Test all services
make verify-all

# Test specific services
cd postgres && ansible-playbook -i ../inventory.yml verify-postgresql.yml
cd harbor && ansible-playbook -i ../inventory.yml verify-harbor.yml
cd qemu-agent && ansible-playbook -i ../inventory.yml verify-qemu-guest-agent.yml
```

### CI/CD Pipeline Testing
```bash
# Validate secrets configuration
cd cicd-templates && ./validate-secrets.sh

# Test Harbor connection
docker login 10.100.10.215:8080 -u admin

# Test Artifactory connection
curl -u admin:Admin123! http://10.100.10.215:8081/artifactory/api/system/ping
```

##  **Deployment Scenarios**

### Full Stack Deployment
```bash
# 1. Deploy infrastructure services
make deploy-postgres deploy-redis deploy-minio

# 2. Deploy DevOps tools
make deploy-harbor deploy-jfrog

# 3. Setup container orchestration
make deploy-kubernetes

# 4. Configure CI/CD
make setup-cicd
```

### Development Environment
```bash
# Minimal development setup
make deploy-harbor deploy-jfrog deploy-postgres

# Setup CI/CD for your project
cd /path/to/your-project
/path/to/ansible-infra/cicd-templates/setup.sh . --interactive
```

### Production Environment
```bash
# Full production deployment
make deploy-all

# Verify all services
make verify-all

# Setup monitoring and maintenance
make maintenance-all
```

##  **Documentation**

### Service-Specific Documentation
- **[Harbor Setup Guide](./harbor/README.md)**
- **[JFrog Configuration](./jfrog/README.md)**
- **[PostgreSQL Management](./postgres/README.md)**
- **[Kubernetes Deployment](./kubernetes/README.md)**
- **[CI/CD Templates Guide](./cicd-templates/README.md)**

### CI/CD Documentation
- **[Getting Started with CI/CD](./cicd-templates/docs/getting-started.md)**
- **[.NET WebAPI Example](./cicd-templates/examples/dotnet-webapi.md)**
- **[Complete Overview](./cicd-templates/OVERVIEW.md)**

##  **Contributing**

1. **Fork**the repository
2. **Create**a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit**your changes (`git commit -m 'Add amazing feature'`)
4. **Push**to the branch (`git push origin feature/amazing-feature`)
5. **Open**a Pull Request

##  **Troubleshooting**

### Common Issues

**Service Connection Failures:**
```bash
# Check service status
systemctl status docker
systemctl status postgresql

# Verify network connectivity
telnet 10.100.10.215 8080  # Harbor
telnet 10.100.10.215 8081  # JFrog
```

**Ansible Playbook Failures:**
```bash
# Run with verbose output
ansible-playbook -i inventory.yml -vvv playbook.yml

# Check SSH connectivity
ansible -i inventory.yml all -m ping
```

**CI/CD Pipeline Issues:**
```bash
# Validate secrets
cd cicd-templates && ./validate-secrets.sh

# Check GitHub Actions logs
# Navigate to your repository's Actions tab
```

### Log Locations
- **Harbor**: `/var/log/harbor/`
- **JFrog**: `/opt/jfrog/artifactory/var/log/`
- **PostgreSQL**: `/var/log/postgresql/`
- **Ansible**: `./ansible.log`

##  **Prerequisites & Requirements**

### System Requirements
- **OS**: Ubuntu 20.04+ / CentOS 8+ / RHEL 8+
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB minimum, 100GB recommended
- **Network**: Internet access for package downloads

### Software Requirements
- **Ansible**: 2.9+
- **Python**: 3.8+
- **Docker**: 20.10+
- **Git**: 2.25+

### Network Requirements
- **SSH access**to target servers
- **Internet access**for downloading packages
- **Port access**for services (8080, 8081, 5432, 6379, 9000)

##  **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## **Acknowledgments**

- **Ansible Community**for excellent automation tools
- **Harbor Project**for enterprise container registry
- **JFrog**for universal artifact management
- **PostgreSQL Team**for robust database systems
- **Docker**for containerization technology

---

**Contact**: For questions or support, please open an issue in the repository.

**Links**: 
- [Ansible Documentation](https://docs.ansible.com/)
- [Harbor Documentation](https://goharbor.io/docs/)
- [JFrog Documentation](https://www.jfrog.com/confluence/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

**Star this repository**if you find it useful!