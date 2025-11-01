# Redis and Redis Stack Deployment

This directory contains Ansible playbooks for deploying and managing Redis and Redis Stack on Ubuntu systems.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment Options](#deployment-options)
- [Security](#security)
- [Monitoring](#monitoring)
- [Backup and Recovery](#backup-and-recovery)
- [Troubleshooting](#troubleshooting)
- [File Structure](#file-structure)

## Overview

### Redis Deployment
- **Standard Redis**: High-performance in-memory database
- **Redis Stack**: Redis with additional modules for enhanced functionality

### Supported Redis Stack Modules
- **RedisJSON**: Native JSON data type support
- **RediSearch**: Full-text search and secondary indexing
- **RedisGraph**: Graph database capabilities
- **RedisTimeSeries**: Time series data structures
- **RedisBloom**: Probabilistic data structures (Bloom filters, etc.)

##  Features

### Security
- ACL-based authentication with multiple user roles
- Configurable user permissions
- Disabled dangerous commands
- TLS/SSL support (optional)
- Ansible Vault for password encryption

###  Configuration
- Production-ready configuration templates
- Performance tuning for different workloads
- Memory optimization settings
- Persistence configuration (RDB + AOF)
- Log rotation and management

###  Monitoring & Operations
- Comprehensive verification playbooks
- Health checks and status monitoring
- Automated backup system
- Service management and systemd integration

###  High Availability
- Master-slave replication support
- Cluster configuration ready
- Failover mechanisms

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04 LTS or Ubuntu 22.04 LTS
- **Memory**: Minimum 2GB RAM (4GB+ recommended for Redis Stack)
- **Storage**: SSD recommended for optimal performance
- **Network**: Open port 6379 (or custom port)

### Control Machine
- **Ansible**: Version 2.9+ (tested with 2.16.3)
- **Python**: 3.8+
- **SSH**: Key-based authentication to target hosts

### Target Hosts
- **Python**: 3.8+ installed
- **Sudo**: Access for deployment user
- **SSH**: Key-based access configured

## Quick Start

### 1. Prepare Inventory
Update the main inventory file to include your Redis hosts:

```yaml
# /home/tshepo/ansible-infra/inventory.yml
[redis]
redis-1 ansible_host=10.100.10.221 ansible_user=ubuntu
redis-2 ansible_host=10.100.10.222 ansible_user=ubuntu
```

### 2. Configure Variables
Edit `vars.yml` to customize your deployment:

```yaml
# Choose service type
redis_service_type: "redis"  # or "redis-stack"

# Network configuration
redis_bind_address: "0.0.0.0"  # Bind to all interfaces
redis_port: 6379

# Authentication
redis_auth_enabled: true
```

### 3. Set Up Vault
Create encrypted password file:

```bash
# Copy example file
cp vault.yml.example vault.yml

# Edit with your passwords
nano vault.yml

# Encrypt the file
ansible-vault encrypt vault.yml
```

### 4. Deploy Redis

#### Standard Redis
```bash
./deploy-redis.sh redis deploy-vault
```

#### Redis Stack (with modules)
```bash
./deploy-redis.sh redis-stack deploy-vault
```

### 5. Verify Deployment
The deployment script automatically runs verification, but you can run it manually:

```bash
ansible-playbook -i ../inventory.yml verify-redis.yml --ask-become-pass --ask-vault-pass
```

##  Configuration

### Service Types

#### Standard Redis
- Core Redis functionality
- High performance in-memory database
- Basic data structures (strings, lists, sets, hashes, etc.)
- Pub/Sub messaging
- Lua scripting

#### Redis Stack
- All standard Redis features
- **RedisJSON**: Store and manipulate JSON documents
- **RediSearch**: Full-text search with indexing
- **RedisGraph**: Graph database operations
- **RedisTimeSeries**: Time series data handling
- **RedisBloom**: Probabilistic data structures

### Key Configuration Options

#### Network Settings
```yaml
redis_bind_address: "127.0.0.1"  # Bind address
redis_port: 6379                 # Port number
redis_tcp_backlog: 511           # TCP backlog
redis_timeout: 0                 # Client timeout (0 = no timeout)
```

#### Memory Management
```yaml
redis_maxmemory: "2gb"                    # Memory limit
redis_maxmemory_policy: "allkeys-lru"     # Eviction policy
redis_maxmemory_samples: 5                # LRU samples
```

#### Persistence
```yaml
# RDB Snapshots
redis_save_rules:
  - "3600 1"      # Save if 1+ keys changed in 1 hour
  - "300 100"     # Save if 100+ keys changed in 5 minutes
  - "60 10000"    # Save if 10000+ keys changed in 1 minute

# AOF (Append Only File)
redis_appendonly: "yes"
redis_appendfsync: "everysec"   # Options: always, everysec, no
```

#### Security
```yaml
redis_auth_enabled: true
redis_app_user: "app_user"
redis_readonly_user: "readonly_user"

# Disabled commands for security
redis_disabled_commands:
  - "FLUSHDB"
  - "FLUSHALL"
  - "CONFIG"
  - "SHUTDOWN"
```

## Security

### Authentication
The deployment creates multiple user accounts with different permission levels:

#### Standard Redis Users
- **app_user**: Full read/write access for applications
- **readonly_user**: Read-only access for monitoring/reporting

#### Redis Stack Users (additional)
- **dev_user**: Development access with module permissions

### User Permissions
```bash
# Application user - full access except dangerous commands
user app_user on >password ~* &* +@all -flushall -flushdb -shutdown -debug -config

# Read-only user - monitoring and read operations
user readonly_user on >password ~* +@read +info +ping +client +latency

# Development user (Redis Stack) - includes module access
user dev_user on >password ~* &* +@all +module
```

### TLS/SSL Configuration
To enable TLS (optional):

```yaml
redis_tls_enabled: true
redis_tls_port: 6380
redis_tls_cert_file: "/etc/redis/tls/redis.crt"
redis_tls_key_file: "/etc/redis/tls/redis.key"
redis_tls_ca_cert_file: "/etc/redis/tls/ca.crt"
```

##  Monitoring

### Health Checks
The verification playbook checks:
- Service status and availability
- Connection testing
- Basic operations (SET/GET/DEL)
- Module functionality (Redis Stack)
- Configuration validation
- Performance metrics

### Key Metrics to Monitor
- **Memory usage**: `INFO memory`
- **Connected clients**: `INFO clients`
- **Operations per second**: `INFO stats`
- **Keyspace information**: `INFO keyspace`
- **Replication status**: `INFO replication`

### Monitoring Commands
```bash
# Basic connection test
redis-cli -h <host> -p 6379 -a <password> ping

# Memory usage
redis-cli -h <host> -p 6379 -a <password> INFO memory

# Performance stats
redis-cli -h <host> -p 6379 -a <password> INFO stats

# Connected clients
redis-cli -h <host> -p 6379 -a <password> CLIENT LIST
```

##  Backup and Recovery

### Automatic Backups
- Daily backups scheduled via cron (2:00 AM for Redis, 2:15 AM for Redis Stack)
- Backup retention: 7 days (configurable)
- Compressed backup files (gzip)
- Background save operations (BGSAVE)

### Backup Locations
- **Redis**: `/var/backups/redis/`
- **Redis Stack**: `/var/backups/redis-stack/`

### Manual Backup
```bash
# Run backup script manually
sudo /usr/local/bin/redis-backup.sh
# or for Redis Stack
sudo /usr/local/bin/redis-stack-backup.sh
```

### Recovery Process
1. Stop Redis service
2. Replace dump.rdb with backup file
3. Start Redis service
4. Verify data integrity

```bash
# Example recovery
sudo systemctl stop redis-server
sudo cp /var/backups/redis/redis_backup_20251031_020001.rdb.gz /tmp/
sudo gunzip /tmp/redis_backup_20251031_020001.rdb.gz
sudo cp /tmp/redis_backup_20251031_020001.rdb /var/lib/redis/dump.rdb
sudo chown redis:redis /var/lib/redis/dump.rdb
sudo systemctl start redis-server
```

##  Troubleshooting

### Common Issues

#### Connection Refused
```bash
# Check service status
sudo systemctl status redis-server

# Check if Redis is listening
sudo netstat -tlnp | grep 6379

# Check logs
sudo tail -f /var/log/redis/redis-server.log
```

#### Authentication Failures
```bash
# Verify ACL users
redis-cli -h localhost -p 6379 ACL LIST

# Test specific user
redis-cli -h localhost -p 6379 -a <password> --user <username> ping
```

#### Memory Issues
```bash
# Check memory usage
redis-cli INFO memory

# Check maxmemory setting
redis-cli CONFIG GET maxmemory

# Monitor memory pattern
redis-cli --latency-history -i 1
```

#### Redis Stack Module Issues
```bash
# List loaded modules
redis-cli MODULE LIST

# Test specific module
redis-cli FT.INFO  # RediSearch
redis-cli JSON.GET # RedisJSON
```

### Log Files
- **Redis**: `/var/log/redis/redis-server.log`
- **Redis Stack**: `/var/log/redis-stack/redis-stack-server.log`
- **Backup logs**: `/var/log/redis/backup.log`

### Performance Tuning
```bash
# Check slow queries
redis-cli SLOWLOG GET 10

# Monitor latency
redis-cli --latency

# Check configuration
redis-cli CONFIG GET "*"
```

##  File Structure

```
redis/
├── deploy-redis.sh              # Main deployment script
├── install-redis.yml            # Standard Redis installation
├── install-redis-stack.yml      # Redis Stack installation
├── verify-redis.yml             # Verification playbook
├── vars.yml                     # Configuration variables
├── vault.yml.example           # Password template
├── README.md                   # This documentation
└── templates/
    ├── redis.conf.j2           # Redis configuration template
    └── redis-stack.conf.j2     # Redis Stack configuration template
```

### Key Files Description

#### Playbooks
- **install-redis.yml**: Deploys standard Redis with security and performance optimizations
- **install-redis-stack.yml**: Deploys Redis Stack with all modules enabled
- **verify-redis.yml**: Comprehensive testing and verification of Redis installation

#### Configuration
- **vars.yml**: All configuration variables (network, security, performance)
- **vault.yml**: Encrypted passwords and sensitive data
- **templates/**: Jinja2 templates for Redis configuration files

#### Scripts
- **deploy-redis.sh**: Automated deployment script with error handling and verification

## Deployment Commands Used

### Standard Redis Deployment:
```bash
cd /home/tshepo/ansible-infra/redis
ansible-playbook -i ../inventory.yml install-redis.yml --ask-vault-pass
ansible-playbook -i ../inventory.yml verify-redis.yml
```

### Redis Stack Deployment:
```bash
ansible-playbook -i ../inventory.yml install-redis-stack.yml --ask-vault-pass
ansible-playbook -i ../inventory.yml verify-redis-stack.yml
```


##  Advanced Configuration

### Cluster Mode
For Redis Cluster setup, modify the configuration:

```yaml
redis_cluster_enabled: "yes"
redis_cluster_config_file: "nodes-6379.conf"
redis_cluster_node_timeout: 15000
```

### Replication
For master-slave replication:

```yaml
# On slave nodes
redis_slaveof_ip: "192.168.1.100"
redis_slaveof_port: 6379
redis_masterauth: "master_password"
```

### Custom Modules
To load additional modules:

```yaml
redis_modules:
  - "/usr/lib/redis/modules/custom-module.so"
```

## Performance Optimization

### System-level Optimizations
The playbooks automatically configure:
- Memory overcommit settings
- TCP backlog optimization
- Transparent Huge Pages disabled
- File descriptor limits
- Network buffer sizes

### Application-level Tuning
- Connection pooling recommended
- Pipeline operations when possible
- Use appropriate data structures
- Monitor memory usage patterns
- Configure appropriate eviction policies
### Future Enhancements:
1. **Security Hardening:**
   - Resolve ACL startup conflicts and enable authentication
   - Configure firewall rules
   - Implement TLS encryption

2. **Monitoring Setup:**
   - Install Redis monitoring tools
   - Configure log aggregation
   - Set up alerting for critical metrics

3. **High Availability:**
   - Consider Redis Sentinel for automatic failover
   - Implement Redis Cluster for horizontal scaling
   - Set up cross-datacenter replication

4. **Redis Stack Modules:**
   - Evaluate actual Redis Stack package availability
   - Consider manual module compilation if needed
   - Test RedisJSON, RedisGraph, RedisTimeSeries functionality

##  Contributing

To contribute improvements:
1. Test changes in development environment
2. Update documentation
3. Ensure security best practices
4. Add verification tests

##  License

This deployment configuration is provided as-is for infrastructure automation purposes.

---

**Note**: Always test deployments in a development environment before applying to production systems.