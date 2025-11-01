# Harbor Container Registry Deployment

This directory contains Ansible playbooks and scripts for deploying and managing Harbor container registry in the infrastructure.

## Overview

Harbor is an open-source trusted cloud-native registry project that stores, signs, and scans content. This deployment provides:

- **High Availability**: SSL-enabled Harbor with PostgreSQL backend
- **Security**: TLS encryption, vulnerability scanning, image signing
- **Authentication**: LDAP/AD integration support and role-based access control
- **Automation**: Complete deployment, backup, and management automation
- **Integration**: Docker/containerd integration for Kubernetes clusters

## Infrastructure Requirements

### Target Hosts
- **harbor-1**: 10.100.10.216 (Primary Harbor registry)
- **Hardware**: 4+ CPU cores, 8+ GB RAM, 100+ GB storage
- **OS**: Ubuntu 22.04 LTS or compatible
- **Network**: Accessible from Kubernetes cluster and development machines

### Dependencies
- Docker Engine 20.10+
- Docker Compose v2.0+
- PostgreSQL 13+ (for production deployment)
- SSL certificates (auto-generated or custom)

## Directory Structure

```
harbor/
├── deploy-harbor.sh              # Main deployment script
├── install-harbor.yml            # Harbor installation playbook
├── verify-harbor.yml             # Installation verification
├── manage-harbor.yml             # Service management
├── backup-harbor.yml             # Backup automation
├── vars.yml                      # Configuration variables
├── vault.yml.example             # Encrypted secrets template
├── tasks/
│   ├── install-docker.yml        # Docker installation
│   ├── install-docker-compose.yml # Docker Compose setup
│   └── generate-ssl-certs.yml    # SSL certificate generation
├── templates/
│   ├── harbor.yml.j2             # Harbor configuration
│   ├── harbor.service.j2         # Systemd service
│   ├── daemon.json.j2            # Docker daemon config
│   ├── harbor-start.sh.j2        # Service start script
│   └── harbor-stop.sh.j2         # Service stop script
└── README.md                     # This documentation
```

## Configuration

### 1. Variables Configuration

Edit `vars.yml` to customize Harbor deployment:

```yaml
# Harbor configuration
harbor_version: "v2.10.0"
harbor_hostname: "harbor-1.local"
harbor_data_dir: "/data/harbor"
harbor_install_dir: "/opt"

# SSL configuration
harbor_ssl_enabled: true
harbor_ssl_cert_dir: "/etc/ssl/harbor"

# Database configuration
harbor_db_host: "localhost"
harbor_db_port: 5432
harbor_db_name: "harbor"
harbor_db_username: "harbor"

# Authentication
harbor_admin_username: "admin"
```

### 2. Secrets Configuration

Create vault file from template:

```bash
cp vault.yml.example vault.yml
ansible-vault edit vault.yml
```

Configure encrypted secrets:
- Database passwords
- Admin passwords
- SSL certificate keys
- LDAP/AD credentials (if used)

### 3. Inventory Configuration

Ensure Harbor hosts are defined in `../inventory.yml`:

```yaml
registries:
  hosts:
    harbor-1:
      ansible_host: 10.100.10.216
      ansible_user: ubuntu
```

## Deployment

### Quick Start

1. **Configure variables and secrets**:
   ```bash
   cd harbor/
   cp vault.yml.example vault.yml
   ansible-vault edit vault.yml
   vim vars.yml
   ```

2. **Deploy Harbor**:
   ```bash
   ./deploy-harbor.sh install --vault-pass
   ```

3. **Verify deployment**:
   ```bash
   ./deploy-harbor.sh verify
   ```

### Detailed Deployment Process

The installation process includes:

1. **Prerequisites**: Docker and Docker Compose installation
2. **SSL Certificates**: Auto-generation of self-signed certificates
3. **Harbor Download**: Harbor v2.10.0 installation packages
4. **Configuration**: Harbor.yml and Docker daemon configuration
5. **Database Setup**: PostgreSQL container configuration
6. **Service Integration**: Systemd service creation and enablement
7. **Health Verification**: API accessibility and component status

### Post-Installation Configuration

1. **Access Harbor Web UI**:
   - URL: `https://harbor-1.local` (or configured hostname)
   - Username: `admin`
   - Password: (from vault.yml)

2. **Configure Projects**:
   ```bash
   # Create public project for Kubernetes
   curl -X POST "https://harbor-1.local/api/v2.0/projects" \
     -H "Content-Type: application/json" \
     -d '{"project_name":"kubernetes","public":true}'
   ```

3. **Docker Login**:
   ```bash
   docker login harbor-1.local
   ```

## Management Commands

### Service Management

```bash
# Start Harbor services
./deploy-harbor.sh start --vault-pass

# Stop Harbor services
./deploy-harbor.sh stop --vault-pass

# Restart Harbor services
./deploy-harbor.sh restart --vault-pass

# Check service status
ansible-playbook -i ../inventory.yml manage-harbor.yml -e "harbor_action=status"
```

### Manual Service Control

```bash
# Using systemctl
sudo systemctl start harbor
sudo systemctl stop harbor
sudo systemctl restart harbor
sudo systemctl status harbor

# Using Docker Compose
cd /opt/harbor
sudo docker-compose start
sudo docker-compose stop
sudo docker-compose restart
sudo docker-compose ps
```

## Backup and Recovery

### Automated Backup

```bash
# Create full backup
./deploy-harbor.sh backup --vault-pass
```

The backup includes:
- Harbor database (PostgreSQL dump)
- Configuration files
- Registry data and images
- SSL certificates
- Service configurations

Backups are stored in `/backup/harbor/` with timestamp.

### Manual Backup

```bash
# Database backup
docker exec harbor-db pg_dump -U harbor harbor > harbor-db-backup.sql

# Configuration backup
tar -czf harbor-config.tar.gz /opt/harbor/

# Data backup
tar -czf harbor-data.tar.gz /data/harbor/
```

### Recovery Process

1. **Stop Harbor services**:
   ```bash
   sudo systemctl stop harbor
   ```

2. **Restore database**:
   ```bash
   docker exec -i harbor-db psql -U harbor harbor < harbor-db-backup.sql
   ```

3. **Restore configuration and data**:
   ```bash
   tar -xzf harbor-config.tar.gz -C /
   tar -xzf harbor-data.tar.gz -C /
   ```

4. **Start Harbor services**:
   ```bash
   sudo systemctl start harbor
   ```

## Integration with Kubernetes

### Configure Kubernetes to Use Harbor

1. **Create Docker registry secret**:
   ```bash
   kubectl create secret docker-registry harbor-registry \
     --docker-server=harbor-1.local \
     --docker-username=admin \
     --docker-password=<harbor-admin-password> \
     --docker-email=admin@company.com
   ```

2. **Configure containerd for Harbor** (on nodes):
   ```bash
   # Add to /etc/containerd/config.toml
   [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor-1.local".auth]
     username = "admin"
     password = "<harbor-admin-password>"
   
   # Restart containerd
   sudo systemctl restart containerd
   ```

3. **Use Harbor in Pod specs**:
   ```yaml
   spec:
     imagePullSecrets:
     - name: harbor-registry
     containers:
     - image: harbor-1.local/kubernetes/my-app:latest
   ```

## Monitoring and Maintenance

### Health Checks

```bash
# API health check
curl -k https://harbor-1.local/api/v2.0/systeminfo

# Service status
./deploy-harbor.sh verify

# Component status
ansible-playbook -i ../inventory.yml manage-harbor.yml -e "harbor_action=status"
```

### Log Monitoring

```bash
# Harbor logs
sudo journalctl -u harbor -f

# Docker Compose logs
cd /opt/harbor
sudo docker-compose logs -f

# Individual service logs
sudo docker logs harbor-core
sudo docker logs harbor-db
sudo docker logs harbor-redis
```

### Storage Management

```bash
# Check storage usage
df -h /data/harbor

# Clean up unused images
docker system prune -a

# Harbor garbage collection
cd /opt/harbor
sudo docker-compose exec harbor-core harbor-gc
```

## Security Considerations

### SSL/TLS Configuration
- Self-signed certificates auto-generated for development
- Production deployments should use CA-signed certificates
- Update `harbor_ssl_cert_path` and `harbor_ssl_key_path` in vars.yml

### Network Security
- Harbor UI accessible on port 443 (HTTPS)
- Docker registry on port 443
- PostgreSQL on internal Docker network only
- Configure firewall rules as needed

### Authentication
- Default admin account with secure password
- LDAP/AD integration available
- Role-based access control (RBAC)
- Project-level permissions

### Vulnerability Scanning
- Trivy scanner integrated
- Automatic vulnerability scanning
- Security policies enforcement
- Image signing with Notary

## Troubleshooting

### Common Issues

1. **Certificate Issues**:
   ```bash
   # Regenerate certificates
   ansible-playbook -i ../inventory.yml tasks/generate-ssl-certs.yml
   ```

2. **Database Connection**:
   ```bash
   # Check database container
   docker exec -it harbor-db psql -U harbor -d harbor
   ```

3. **Storage Space**:
   ```bash
   # Clean up old images
   cd /opt/harbor
   docker-compose exec harbor-core harbor-gc
   ```

4. **Service Start Issues**:
   ```bash
   # Check logs
   sudo journalctl -u harbor -n 50
   sudo docker-compose logs --tail=50
   ```

### Support Commands

```bash
# Full system information
./deploy-harbor.sh verify --verbose

# Component status check
ansible-playbook -i ../inventory.yml manage-harbor.yml -e "harbor_action=status" --verbose

# Manual service inspection
sudo systemctl status harbor --no-pager -l
```

## Version Information

- **Harbor Version**: v2.10.0
- **Docker Version**: 24.0+
- **Docker Compose**: v2.0+
- **PostgreSQL**: 13-alpine
- **Redis**: 7-alpine
- **Trivy Scanner**: Latest

## References

- [Harbor Official Documentation](https://goharbor.io/docs/)
- [Harbor Installation Guide](https://goharbor.io/docs/2.10.0/install-config/)
- [Kubernetes Integration](https://goharbor.io/docs/2.10.0/working-with-projects/working-with-images/pulling-pushing-images/)
- [Harbor API Reference](https://goharbor.io/docs/2.10.0/build-customize-contribute/configure-swagger/)

---

**Note**: This deployment is optimized for development and testing environments. For production deployments, consider external PostgreSQL, Redis clusters, and load balancing configurations.