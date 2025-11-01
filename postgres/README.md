# PostgreSQL Automation

This directory contains Ansible playbooks and scripts for automated PostgreSQL deployment, configuration, and management.

## Overview

PostgreSQL is a powerful, open-source object-relational database system with over 30 years of active development. This automation provides:

- **Automated Installation**: Deploy PostgreSQL with optimal configurations
- **Security Hardening**: SSL/TLS encryption, user management, authentication
- **Performance Tuning**: Memory optimization, connection pooling, query optimization
- **Backup Solutions**: Automated backup strategies with point-in-time recovery
- **Monitoring Setup**: Health checks, performance metrics, alerting
- **High Availability**: Replication setup for production environments

## Files Structure

```
postgres/
├── README.md                    # This documentation
├── deploy-postgresql.sh         # Main deployment script
├── install-postgresql.yml       # Ansible playbook for installation
├── maintenance-postgresql.yml   # Maintenance and optimization tasks
├── verify-postgresql.yml        # Verification and health checks
├── vars.yml                     # Configuration variables
├── vault.yml.example           # Encrypted variables template
└── templates/                   # Configuration templates
    ├── postgresql.conf.j2       # Main PostgreSQL configuration
    ├── pg_hba.conf.j2          # Authentication configuration
    ├── recovery.conf.j2         # Recovery configuration
    └── backup-script.sh.j2      # Backup automation script
```

## Quick Start

### 1. Configure Variables
```bash
# Copy and edit configuration
cp vault.yml.example vault.yml
ansible-vault edit vault.yml

# Review and modify vars.yml
vim vars.yml
```

### 2. Deploy PostgreSQL
```bash
# Run automated deployment
./deploy-postgresql.sh

# Or use Ansible directly
ansible-playbook -i ../inventory.yml install-postgresql.yml
```

### 3. Verify Installation
```bash
# Run verification checks
ansible-playbook -i ../inventory.yml verify-postgresql.yml
```

## Configuration

### Core Variables (`vars.yml`)

#### Database Configuration
```yaml
postgresql:
  version: "15"
  port: 5432
  data_directory: "/var/lib/postgresql/15/main"
  max_connections: 200
  shared_buffers: "256MB"
  effective_cache_size: "1GB"
```

#### Security Settings
```yaml
postgresql_security:
  ssl_enabled: true
  authentication_method: "md5"
  allowed_networks:
    - "127.0.0.1/32"
    - "10.0.0.0/8"
    - "192.168.0.0/16"
```

#### User Management
```yaml
postgresql_users:
  - name: "app_user"
    password: "{{ vault_app_user_password }}"
    privileges: "CREATEDB"
    databases: ["app_db"]
  - name: "readonly_user"
    password: "{{ vault_readonly_password }}"
    privileges: "LOGIN"
```

### Encrypted Variables (`vault.yml`)

Store sensitive information in encrypted format:
```yaml
# Database passwords
vault_postgres_password: "secure_admin_password"
vault_app_user_password: "secure_app_password"
vault_readonly_password: "secure_readonly_password"
vault_backup_user_password: "secure_backup_password"

# Replication settings
vault_replication_password: "secure_replication_password"

# SSL certificates (if using custom certs)
vault_ssl_cert_content: |
  -----BEGIN CERTIFICATE-----
  [certificate content]
  -----END CERTIFICATE-----

vault_ssl_key_content: |
  -----BEGIN PRIVATE KEY-----
  [private key content]
  -----END PRIVATE KEY-----
```

## Features

### 1. Automated Installation
- PostgreSQL server and client installation
- Required extensions (uuid-ossp, pg_stat_statements, etc.)
- Python PostgreSQL adapter (psycopg2)
- Backup utilities (pg_dump, pg_basebackup)

### 2. Security Configuration
- SSL/TLS encryption setup
- Authentication method configuration
- User and role management
- Network access control
- Password policy enforcement

### 3. Performance Optimization
- Memory configuration tuning
- Connection pooling setup
- Auto-vacuum optimization
- Query performance monitoring
- Index optimization recommendations

### 4. Backup and Recovery
- Automated backup scheduling
- Multiple backup strategies (logical/physical)
- Point-in-time recovery configuration
- Backup verification and testing
- Off-site backup storage setup

### 5. Monitoring and Alerting
- Performance metrics collection
- Health check automation
- Resource usage monitoring
- Slow query detection
- Alert configuration for critical events

### 6. High Availability
- Streaming replication setup
- Automatic failover configuration
- Load balancing configuration
- Backup server management
- Split-brain prevention

## Usage Examples

### Basic Deployment
```bash
# Deploy PostgreSQL with default settings
./deploy-postgresql.sh --env production

# Deploy to specific hosts
ansible-playbook -i inventory.yml install-postgresql.yml --limit database_servers
```

### Maintenance Operations
```bash
# Run maintenance tasks
ansible-playbook -i inventory.yml maintenance-postgresql.yml

# Update PostgreSQL configuration
ansible-playbook -i inventory.yml install-postgresql.yml --tags config

# Perform backup operations
ansible-playbook -i inventory.yml maintenance-postgresql.yml --tags backup
```

### Verification and Testing
```bash
# Verify installation
ansible-playbook -i inventory.yml verify-postgresql.yml

# Test database connectivity
ansible-playbook -i inventory.yml verify-postgresql.yml --tags connectivity

# Performance testing
ansible-playbook -i inventory.yml verify-postgresql.yml --tags performance
```

## Management Tasks

### User Management
```sql
-- Create application user
CREATE USER app_user WITH PASSWORD 'secure_password';
CREATE DATABASE app_db OWNER app_user;
GRANT ALL PRIVILEGES ON DATABASE app_db TO app_user;

-- Create read-only user
CREATE USER readonly_user WITH PASSWORD 'readonly_password';
GRANT CONNECT ON DATABASE app_db TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

### Backup Operations
```bash
# Manual backup
pg_dump -h localhost -U postgres -d app_db -f backup_$(date +%Y%m%d).sql

# Automated backup (configured via playbook)
/opt/postgresql/scripts/backup.sh

# Restore from backup
psql -h localhost -U postgres -d app_db -f backup_20241102.sql
```

### Performance Monitoring
```sql
-- Check database sizes
SELECT datname, pg_size_pretty(pg_database_size(datname)) 
FROM pg_database ORDER BY pg_database_size(datname) DESC;

-- Monitor slow queries
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC LIMIT 10;

-- Check connection status
SELECT datname, usename, client_addr, state 
FROM pg_stat_activity 
WHERE state = 'active';
```

## Security Best Practices

### 1. Authentication
- Use strong passwords (minimum 12 characters)
- Implement certificate-based authentication for replication
- Enable SSL for all connections
- Regular password rotation

### 2. Network Security
- Configure firewall rules for PostgreSQL port
- Use VPN for remote database access
- Implement IP whitelisting
- Network segmentation for database servers

### 3. Data Protection
- Enable transparent data encryption
- Regular security updates
- Audit logging configuration
- Backup encryption

### 4. Access Control
- Principle of least privilege
- Role-based access control
- Regular access reviews
- Database activity monitoring

## Troubleshooting

### Common Issues

#### Connection Problems
```bash
# Check PostgreSQL status
systemctl status postgresql

# Verify port listening
netstat -tlnp | grep 5432

# Test local connection
psql -h localhost -U postgres

# Check authentication configuration
tail -f /var/log/postgresql/postgresql-*.log
```

#### Performance Issues
```sql
-- Check current connections
SELECT count(*) FROM pg_stat_activity;

-- Identify long-running queries
SELECT pid, query_start, query 
FROM pg_stat_activity 
WHERE state = 'active' 
AND query_start < now() - interval '5 minutes';

-- Check table bloat
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### Replication Issues
```sql
-- Check replication status
SELECT * FROM pg_stat_replication;

-- Monitor replication lag
SELECT client_addr, state, 
       pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) as send_lag,
       pg_wal_lsn_diff(sent_lsn, flush_lsn) as flush_lag
FROM pg_stat_replication;
```

### Log Analysis
```bash
# PostgreSQL error logs
tail -f /var/log/postgresql/postgresql-*.log

# Filter for specific errors
grep -i "error\|fatal\|panic" /var/log/postgresql/postgresql-*.log

# Analyze slow queries
grep -i "duration\|slow" /var/log/postgresql/postgresql-*.log
```

## Integration

### With CI/CD Pipelines
- Database migration automation
- Schema version control
- Performance regression testing
- Backup validation in CI

### With Monitoring Systems
- Prometheus metrics export
- Grafana dashboard templates
- AlertManager integration
- Log aggregation (ELK stack)

### With Container Orchestration
- Kubernetes operator deployment
- Docker Compose configurations
- Helm chart templates
- StatefulSet configurations

## Support and Documentation

- **Comprehensive Management Guide**: [PostgreSQL Management Guide](../cicd-templates/docs/POSTGRESQL_MANAGEMENT_GUIDE.md)
- **Official Documentation**: https://www.postgresql.org/docs/
- **Community Support**: https://www.postgresql.org/support/
- **Performance Tuning**: https://pgtune.leopard.in.ua/

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes thoroughly
4. Submit a pull request
5. Update documentation

## License

This automation is provided under the same license as the main project.