# MinIO Object Storage Deployment

This directory contains Ansible playbooks and scripts for deploying MinIO Object Storage on Ubuntu servers.

## Overview

MinIO is a high-performance, distributed object storage system that is API-compatible with Amazon S3. This deployment provides:

- **Single-node MinIO installation** with systemd service management
- **Web-based console** for administration
- **Automated backup system** with retention policies
- **Health monitoring** and alerting capabilities
- **Default bucket creation** with configurable policies
- **Security hardening** with firewall rules and system limits
- **Performance optimization** with kernel parameter tuning

## Files Structure

```
minio/
├── install-minio.yml           # Main installation playbook
├── verify-minio.yml            # Verification and testing playbook
├── vars.yml                    # Configuration variables
├── vault.yml.example          # Example encrypted credentials
├── deploy-minio.sh            # Deployment automation script
├── templates/
│   ├── minio.env.j2           # MinIO environment configuration
│   ├── minio.service.j2       # SystemD service file
│   ├── minio.logrotate.j2     # Log rotation configuration
│   ├── minio-backup.sh.j2     # Backup automation script
│   └── minio-health-check.sh.j2  # Health monitoring script
└── README.md                  # This file
```

## Quick Start

### 1. Create Vault File
```bash
cd /home/tshepo/ansible-infra/minio
./deploy-minio.sh create-vault
```

### 2. Deploy MinIO
```bash
./deploy-minio.sh full-deploy --vault-pass --verbose
```

### 3. Verify Installation
```bash
./deploy-minio.sh verify --vault-pass
```

## Manual Deployment

### Step 1: Prepare Credentials
```bash
# Copy example vault file
cp vault.yml.example vault.yml

# Edit the vault file with your passwords
nano vault.yml

# Encrypt the vault file
ansible-vault encrypt vault.yml
```

### Step 2: Review Configuration
Edit `vars.yml` to customize:
- MinIO version and paths
- Network configuration
- Storage settings
- Backup schedules
- Default buckets

### Step 3: Run Installation
```bash
ansible-playbook -i ../inventory.yml install-minio.yml --ask-vault-pass
```

### Step 4: Verify Deployment
```bash
ansible-playbook -i ../inventory.yml verify-minio.yml --ask-vault-pass
```

## Configuration

### Default Settings
- **MinIO Server Port**: 9000
- **MinIO Console Port**: 9001
- **Data Directory**: `/data/minio`
- **Config Directory**: `/etc/minio`
- **Backup Directory**: `/backup/minio`
- **Log Directory**: `/var/log/minio`

### Default Buckets
The installation creates these buckets automatically:
- `data` (private) - General data storage
- `backups` (private) - Backup storage
- `logs` (private) - Log file storage
- `uploads` (public-read) - File uploads

### Security Features
- Firewall rules for MinIO ports
- System user isolation
- File permission hardening
- Resource limits configuration
- Network access restrictions

## Access URLs

After deployment, MinIO will be available at:
- **Server API**: `http://<server-ip>:9000`
- **Web Console**: `http://<server-ip>:9001`

Based on your inventory (`minio-1: 10.100.10.226`):
- **Server API**: `http://10.100.10.226:9000`
- **Web Console**: `http://10.100.10.226:9001`

## Backup System

### Automated Backups
- **Schedule**: Daily at 3:00 AM
- **Retention**: 30 days (configurable)
- **Location**: `/backup/minio/`
- **Format**: Compressed tar.gz archives

### Manual Backup
```bash
# On the MinIO server
sudo /usr/local/bin/minio-backup.sh

# Or remotely via Ansible
ansible storage -i ../inventory.yml -m shell -a "/usr/local/bin/minio-backup.sh" -b
```

### Backup Contents
- All bucket data and metadata
- Bucket policies and configurations
- User accounts and service accounts
- Server configuration files

## Health Monitoring

### Automated Health Checks
The system includes comprehensive health monitoring:
- Service status verification
- Port connectivity tests
- Disk space monitoring
- Performance testing
- Admin interface checks

### Manual Health Check
```bash
# On the MinIO server
sudo /usr/local/bin/minio-health-check.sh

# Or remotely via Ansible
ansible storage -i ../inventory.yml -m shell -a "/usr/local/bin/minio-health-check.sh" -b
```

## Management Commands

### Using Deploy Script
```bash
# Full deployment
./deploy-minio.sh full-deploy --vault-pass

# Install only
./deploy-minio.sh install --vault-pass

# Verify installation
./deploy-minio.sh verify

# Run backup
./deploy-minio.sh backup

# Health check
./deploy-minio.sh health-check

# Create new vault
./deploy-minio.sh create-vault
```

### Using Ansible Directly
```bash
# Install MinIO
ansible-playbook -i ../inventory.yml install-minio.yml --ask-vault-pass

# Verify installation
ansible-playbook -i ../inventory.yml verify-minio.yml --ask-vault-pass

# Check service status
ansible storage -i ../inventory.yml -m service -a "name=minio state=started" -b

# Restart MinIO service
ansible storage -i ../inventory.yml -m service -a "name=minio state=restarted" -b
```

### Using MinIO Client (mc)
```bash
# On the MinIO server, configure client
mc alias set local http://localhost:9000 <access-key> <secret-key>

# List buckets
mc ls local/

# Create bucket
mc mb local/my-new-bucket

# Upload file
mc cp /path/to/file local/my-bucket/

# Download file
mc cp local/my-bucket/file /path/to/destination
```

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   ```bash
   # Check service status
   systemctl status minio
   
   # Check logs
   journalctl -u minio -f
   
   # Verify configuration
   minio --config-dir /etc/minio --help
   ```

2. **Permission Issues**
   ```bash
   # Fix data directory permissions
   chown -R minio:minio /data/minio
   chmod -R 755 /data/minio
   ```

3. **Network Connectivity**
   ```bash
   # Check if ports are listening
   netstat -tlnp | grep -E '9000|9001'
   
   # Test local connectivity
   curl http://localhost:9000/minio/health/live
   ```

4. **Disk Space Issues**
   ```bash
   # Check disk usage
   df -h /data/minio
   
   # Clean old backups
   find /backup/minio -name "*.tar.gz" -mtime +30 -delete
   ```

### Log Locations
- **MinIO Service Logs**: `journalctl -u minio`
- **MinIO Application Logs**: `/var/log/minio/minio.log`
- **Backup Logs**: `/var/log/minio/backup.log`
- **Health Check Logs**: `/var/log/minio/health-check.log`

### Configuration Files
- **Environment**: `/etc/minio/minio.env`
- **SystemD Service**: `/etc/systemd/system/minio.service`
- **Log Rotation**: `/etc/logrotate.d/minio`

## Performance Tuning

### System Optimization
The playbook automatically applies these optimizations:
- Increased file descriptor limits
- Network buffer size tuning
- Memory overcommit settings
- TCP connection optimizations

### Storage Recommendations
- Use XFS filesystem for optimal performance
- Mount with `noatime` option
- Ensure adequate IOPS for your workload
- Consider RAID configuration for redundancy

### Network Recommendations
- Use dedicated network interfaces for storage traffic
- Configure appropriate MTU size
- Monitor network bandwidth utilization

## Security Considerations

### Authentication
- Change default root credentials
- Create service-specific users
- Use strong passwords (generated automatically)
- Implement bucket policies appropriately

### Network Security
- Configure firewall rules properly
- Restrict access to management ports
- Use HTTPS in production (TLS configuration available)
- Monitor access logs regularly

### Data Protection
- Enable bucket versioning for critical data
- Implement regular backup verification
- Test disaster recovery procedures
- Monitor data integrity

## Integration Examples

### Backup to MinIO
```bash
# Example backup script
#!/bin/bash
mc cp /important/data local/backups/$(date +%Y%m%d)/
```

### Application Integration
```python
# Python example using boto3
import boto3

s3_client = boto3.client(
    's3',
    endpoint_url='http://10.100.10.226:9000',
    aws_access_key_id='your-access-key',
    aws_secret_access_key='your-secret-key'
)

# Upload file
s3_client.upload_file('local-file.txt', 'my-bucket', 'remote-file.txt')
```

## Maintenance

### Regular Tasks
- Monitor disk usage and clean old backups
- Review and rotate access keys
- Update MinIO to latest stable version
- Check health monitoring alerts
- Verify backup integrity

### Updates
```bash
# Update MinIO version in vars.yml, then:
ansible-playbook -i ../inventory.yml install-minio.yml --ask-vault-pass --tags binary
```

## Support

For issues with this deployment:
1. Check the troubleshooting section above
2. Review MinIO documentation: https://docs.min.io/
3. Check service logs and health checks
4. Verify network connectivity and firewall rules

For MinIO-specific issues:
- MinIO Documentation: https://docs.min.io/
- MinIO Community: https://github.com/minio/minio
- MinIO Slack: https://slack.min.io/