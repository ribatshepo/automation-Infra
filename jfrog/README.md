# JFrog Artifactory - Automated Deployment Guide

## Overview
This enhanced deployment automates all manual interventions that were previously required for JFrog Artifactory deployment, ensuring a smooth, hands-off installation process.

## What's Been Automated

### 1. **Service Startup & Dependencies**
**Problem**: Service dependencies weren't properly managed, causing startup failures.
**Solution**: 
- Updated systemd service with PostgreSQL dependencies
- Extended startup timeout to 600 seconds
- Proper restart policies with backoff

### 2. **Database Initialization Sequence**
**Problem**: Database wasn't ready when Artifactory started.
**Solution**:
- Automated database connectivity verification
- Proper sequencing: PostgreSQL → Database Ready → Artifactory Start
- Automatic retry logic for database connections

### 3. **Master Key Generation**
**Problem**: Master key security files were missing, causing startup failures.
**Solution**:
- Automatic master key generation if missing
- Proper file permissions and ownership
- Verification before service start

### 4. **Service Health Monitoring**
**Problem**: No way to know when service was truly ready.
**Solution**:
- Multi-layered health checks (port, API, UI)
- Wait loops with proper timeouts
- Comprehensive status reporting

### 5. **Admin Password Configuration**
**Problem**: Manual password change required after first login.
**Solution**:
- Automatic detection of default vs custom credentials
- API-based password update from vault.yml
- Verification of new credentials

### 6. **Startup Timeout Handling**
**Problem**: Service took too long to start, causing timeouts.
**Solution**:
- Extended systemd timeouts (600s start, 300s stop)
- Progressive health checks
- Automatic restart on failure

## Enhanced Files Structure

```
jfrog/
├── deploy-artifactory-enhanced.sh      # New enhanced deployment script
├── install-artifactory.yml             # Updated main playbook
├── tasks/
│   ├── wait-for-service.yml            # NEW: Service readiness checks
│   ├── configure-admin.yml             # NEW: Automated admin setup
│   ├── verify-database.yml             # NEW: Database verification
│   ├── start-service.yml               # NEW: Proper service management
│   └── health-check.yml                # NEW: Comprehensive health check
├── templates/
│   └── artifactory.service.j2          # Enhanced systemd service
└── vars.yml / vault.yml                # Configuration files
```

## Usage Guide

### Quick Start (Recommended)
```bash
# Clean installation (removes existing installation)
cd /home/tshepo/ansible-infra/jfrog
./deploy-artifactory-enhanced.sh clean
```

### Available Commands
```bash
# Standard installation
./deploy-artifactory-enhanced.sh install

# Clean installation (removes existing installation)
./deploy-artifactory-enhanced.sh clean

# Verify existing deployment
./deploy-artifactory-enhanced.sh verify

# Service management
./deploy-artifactory-enhanced.sh start
./deploy-artifactory-enhanced.sh stop
./deploy-artifactory-enhanced.sh restart

# Troubleshooting
./deploy-artifactory-enhanced.sh troubleshoot

# Create backup
./deploy-artifactory-enhanced.sh backup

# Show help
./deploy-artifactory-enhanced.sh help
```

## Automated Checks & Fixes

### 1. **Pre-Installation Checks**
- Ansible availability
- Inventory file existence
- Vault file existence
- Playbook syntax validation

### 2. **Database Verification**
- PostgreSQL service status
- Database connectivity
- User permissions
- Table initialization status

### 3. **Service Management**
- Proper shutdown sequence
- Dependency management (PostgreSQL first)
- Master key verification/generation
- Extended startup timeouts
- Automatic restart on failure

### 4. **Health Monitoring**
- Port 8081 accessibility
- API endpoint availability
- UI interface readiness
- Authentication verification
- Database connectivity

### 5. **Admin Configuration**
- Default credential detection
- Automatic password update
- Credential verification
- Error handling for auth failures

## Configuration Details

### Systemd Service Enhancements
```ini
[Unit]
After=network.target postgresql.service
Wants=postgresql.service
RequiresMountsFor=/var/opt/jfrog/artifactory

[Service]
TimeoutStartSec=600          # Extended startup timeout
TimeoutStopSec=300           # Extended stop timeout
Restart=on-failure           # Auto-restart on failure
RestartSec=30                # Wait 30s before restart
StartLimitInterval=600       # Rate limiting
StartLimitBurst=3            # Max 3 restarts per interval
```

### Health Check Features
- **Multi-layered verification**: Service, Port, API, UI, Auth, Database
- **Comprehensive reporting**: Detailed status for each component
- **Access information**: Automatic IP detection and connection details
- **Resource monitoring**: Memory, storage, process counts
- **Log file generation**: Health reports saved to disk

## Troubleshooting Automation

### Automatic Diagnostics
The `troubleshoot` command runs comprehensive diagnostics:
- System information (OS, memory, disk)
- Java version verification
- Service status and logs
- Network port status
- Recent error logs

### Common Issues Automatically Handled
1. **Service won't start**: Extended timeouts + dependency management
2. **Database not ready**: Wait loops + connectivity verification
3. **Master key missing**: Automatic generation + proper permissions
4. **Admin password issues**: Automatic detection + API-based updates
5. **UI not accessible**: Progressive health checks + detailed reporting

## Security Considerations

### Automated Password Management
- Default credentials automatically detected
- Vault-based password configuration
- API-based secure password updates
- Credential verification loops

### File Permissions
- Master key files: 600 (artifactory:artifactory)
- Configuration files: 644 (artifactory:artifactory)
- Log files: 644 with proper ownership
- Health reports: 600 (sensitive information)

## Monitoring & Logging

### Deployment Logs
- All operations logged to `deployment.log`
- Timestamped entries with color coding
- Error details preserved for troubleshooting

### Health Reports
- Comprehensive status saved to `/var/opt/jfrog/artifactory/health-report.txt`
- Include access credentials and connection details
- Regular updates during health checks

## Migration from Old Process

### If you have existing installation:
```bash
# Backup first (optional)
./deploy-artifactory-enhanced.sh backup

# Clean installation with all automations
./deploy-artifactory-enhanced.sh clean
```

### For new installations:
```bash
# Just run the enhanced installer
./deploy-artifactory-enhanced.sh install
```

## Success Indicators

After running the enhanced deployment, you should see:
- Service Status: HEALTHY
- Port 8081: ACCESSIBLE  
- API Endpoint: WORKING
- UI Interface: WORKING
- Admin Login: WORKING
- Database: CONNECTED

And the final message:
```
DEPLOYMENT SUCCESSFUL!
 JFrog Artifactory is ready for use!
 Access the UI at: http://[IP]:8081/ui/
 Login with: admin / [password from vault]
```

## Maintenance

### Regular Health Checks
```bash
./deploy-artifactory-enhanced.sh verify
```

### Service Management
```bash
./deploy-artifactory-enhanced.sh restart  # Includes health check
```

### Troubleshooting
```bash
./deploy-artifactory-enhanced.sh troubleshoot  # Comprehensive diagnostics
```

This enhanced automation eliminates all manual interventions and provides a robust, production-ready JFrog Artifactory deployment process.