# Kubernetes Automation

This directory contains Ansible playbooks and scripts for automated Kubernetes cluster deployment, configuration, and management.

## Overview

Kubernetes is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications. This automation provides:

- **Multi-Stage Deployment**: Preparation, cluster setup, and services configuration
- **High Availability**: Multi-master cluster configuration
- **Security Hardening**: RBAC, network policies, security contexts
- **Monitoring Integration**: Prometheus, Grafana, and alerting setup
- **Storage Management**: Persistent volumes and storage classes
- **Networking**: CNI plugins, ingress controllers, service mesh
- **CI/CD Integration**: GitOps workflows and deployment automation

## Files Structure

```
kubernetes/
├── README.md                    # This documentation
├── deploy-kubernetes.sh         # Main deployment script
├── vars.yml                     # Configuration variables
├── vault.yml                    # Encrypted sensitive data
├── vault.yml.example           # Encrypted variables template
├── group_vars/                  # Group-specific variables
│   ├── all.yml                  # Global variables
│   ├── masters.yml              # Master node variables
│   └── workers.yml              # Worker node variables
├── stage1-preparation/          # Infrastructure preparation
│   ├── 01-system-setup.yml      # System requirements and updates
│   ├── 02-docker-install.yml    # Container runtime installation
│   ├── 03-kubernetes-repo.yml   # Kubernetes repository setup
│   └── 04-firewall-setup.yml    # Network and firewall configuration
├── stage2-cluster/              # Cluster initialization
│   ├── 01-master-init.yml       # Initialize first master node
│   ├── 02-master-join.yml       # Join additional master nodes
│   ├── 03-worker-join.yml       # Join worker nodes
│   ├── 04-network-plugin.yml    # Install CNI plugin
│   └── 05-cluster-verify.yml    # Cluster verification
├── stage3-services/             # Essential services deployment
│   ├── 01-ingress-controller.yml    # Ingress controller setup
│   ├── 02-cert-manager.yml          # Certificate management
│   ├── 03-monitoring-stack.yml      # Prometheus and Grafana
│   ├── 04-logging-stack.yml         # ELK or Loki stack
│   ├── 05-storage-classes.yml       # Storage configuration
│   └── 06-security-policies.yml     # Network and security policies
└── templates/                   # Configuration templates
    ├── kubeconfig.j2            # Kubernetes configuration
    ├── cluster-config.yaml.j2   # Cluster configuration
    ├── ingress-config.yaml.j2   # Ingress configuration
    └── monitoring-values.yaml.j2 # Monitoring stack values
```

## Quick Start

### 1. Prepare Infrastructure
```bash
# Configure inventory
cp ../inventory.yml.example ../inventory.yml
vim ../inventory.yml  # Add your servers

# Configure variables
cp vault.yml.example vault.yml
ansible-vault edit vault.yml
vim vars.yml  # Review and modify settings
```

### 2. Deploy Kubernetes Cluster
```bash
# Run complete deployment
./deploy-kubernetes.sh

# Or run stage by stage
ansible-playbook -i ../inventory.yml stage1-preparation/*.yml
ansible-playbook -i ../inventory.yml stage2-cluster/*.yml
ansible-playbook -i ../inventory.yml stage3-services/*.yml
```

### 3. Access Your Cluster
```bash
# Copy kubeconfig (from master node)
mkdir -p ~/.kube
scp root@master-node:/etc/kubernetes/admin.conf ~/.kube/config

# Verify cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

## Configuration

### Core Variables (`vars.yml`)

#### Cluster Configuration
```yaml
kubernetes:
  version: "1.28.2"
  pod_subnet: "10.244.0.0/16"
  service_subnet: "10.96.0.0/12"
  cluster_name: "production-cluster"
  
  # Master nodes configuration
  masters:
    count: 3
    cpu_cores: 4
    memory_gb: 8
    disk_gb: 100
    
  # Worker nodes configuration
  workers:
    count: 5
    cpu_cores: 8
    memory_gb: 16
    disk_gb: 200
    
  # Network configuration
  network:
    cni_plugin: "calico"  # calico, flannel, weave
    pod_subnet: "10.244.0.0/16"
    service_subnet: "10.96.0.0/12"
    cluster_dns: "10.96.0.10"
```

#### Container Runtime
```yaml
container_runtime:
  name: "containerd"  # docker, containerd, cri-o
  version: "1.7.7"
  
  # Docker configuration (if using Docker)
  docker:
    daemon_json:
      exec-opts: ["native.cgroupdriver=systemd"]
      log-driver: "json-file"
      log-opts:
        max-size: "100m"
        max-file: "3"
      storage-driver: "overlay2"
```

#### Load Balancer Configuration
```yaml
load_balancer:
  enabled: true
  type: "haproxy"  # haproxy, nginx, metallb
  vip: "192.168.1.100"
  
  # HAProxy configuration
  haproxy:
    stats_enabled: true
    stats_port: 8404
    stats_user: "admin"
    stats_password: "{{ vault_haproxy_stats_password }}"
```

#### Storage Configuration
```yaml
storage:
  # Storage classes
  classes:
    - name: "fast-ssd"
      provisioner: "kubernetes.io/aws-ebs"
      parameters:
        type: "gp3"
        fsType: "ext4"
      default: true
      
    - name: "slow-hdd"
      provisioner: "kubernetes.io/aws-ebs"
      parameters:
        type: "st1"
        fsType: "ext4"
        
  # Persistent volumes
  persistent_volumes:
    - name: "database-pv"
      size: "100Gi"
      access_modes: ["ReadWriteOnce"]
      storage_class: "fast-ssd"
```

### Encrypted Variables (`vault.yml`)

Store sensitive information in encrypted format:
```yaml
# Cluster certificates and keys
vault_ca_cert: |
  -----BEGIN CERTIFICATE-----
  [CA certificate content]
  -----END CERTIFICATE-----

vault_ca_key: |
  -----BEGIN PRIVATE KEY-----
  [CA private key content]
  -----END PRIVATE KEY-----

# Service account tokens
vault_admin_token: "admin-service-account-token"
vault_monitoring_token: "monitoring-service-account-token"

# External integrations
vault_harbor_password: "harbor-registry-password"
vault_grafana_admin_password: "grafana-admin-password"
vault_prometheus_password: "prometheus-password"

# Load balancer passwords
vault_haproxy_stats_password: "haproxy-stats-password"

# External DNS credentials (if applicable)
vault_dns_api_key: "dns-provider-api-key"
vault_dns_secret_key: "dns-provider-secret-key"
```

## Features

### 1. Multi-Master High Availability
- Automated load balancer setup
- Etcd cluster configuration
- Master node redundancy
- Automatic failover capabilities

### 2. Security Hardening
- RBAC (Role-Based Access Control)
- Network policies enforcement
- Pod security policies
- Service mesh integration (Istio)
- Secret management with external providers

### 3. Monitoring and Observability
- Prometheus metrics collection
- Grafana dashboards
- AlertManager notifications
- Distributed tracing (Jaeger)
- Log aggregation (ELK/Loki)

### 4. Networking
- Multiple CNI plugin support
- Ingress controller configuration
- Service mesh setup
- Network policy enforcement
- External DNS integration

### 5. Storage Management
- Dynamic volume provisioning
- Storage class configuration
- Persistent volume management
- Backup and snapshot automation
- Multi-cloud storage support

### 6. CI/CD Integration
- GitOps workflows (ArgoCD/Flux)
- Automated deployments
- Rolling updates
- Blue-green deployments
- Canary releases

## Usage Examples

### Cluster Deployment
```bash
# Deploy complete cluster
./deploy-kubernetes.sh --env production

# Deploy specific stages
ansible-playbook -i ../inventory.yml stage1-preparation/01-system-setup.yml
ansible-playbook -i ../inventory.yml stage2-cluster/01-master-init.yml

# Deploy to specific node groups
ansible-playbook -i ../inventory.yml stage1-preparation/*.yml --limit masters
ansible-playbook -i ../inventory.yml stage2-cluster/*.yml --limit workers
```

### Cluster Management
```bash
# Add new worker nodes
ansible-playbook -i ../inventory.yml stage2-cluster/03-worker-join.yml --limit new_workers

# Update cluster components
ansible-playbook -i ../inventory.yml stage2-cluster/*.yml --tags update

# Backup etcd
ansible-playbook -i ../inventory.yml maintenance/backup-etcd.yml
```

### Service Deployment
```bash
# Deploy monitoring stack
ansible-playbook -i ../inventory.yml stage3-services/03-monitoring-stack.yml

# Deploy ingress controller
ansible-playbook -i ../inventory.yml stage3-services/01-ingress-controller.yml

# Update service configurations
ansible-playbook -i ../inventory.yml stage3-services/*.yml --tags config
```

## Management Operations

### Cluster Administration
```bash
# Check cluster health
kubectl cluster-info
kubectl get componentstatuses
kubectl get nodes -o wide

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Node Management
```bash
# Cordon a node (prevent new pods)
kubectl cordon worker-node-1

# Drain a node (move existing pods)
kubectl drain worker-node-1 --ignore-daemonsets --delete-emptydir-data

# Uncordon a node (allow scheduling)
kubectl uncordon worker-node-1

# Remove a node
kubectl delete node worker-node-1
```

### Application Deployment
```bash
# Deploy application with Helm
helm repo add stable https://charts.helm.sh/stable
helm install my-app stable/nginx-ingress

# Deploy with kubectl
kubectl apply -f deployment.yaml
kubectl apply -k kustomization/

# Check deployment status
kubectl rollout status deployment/my-app
kubectl get pods -l app=my-app
```

### Backup and Recovery
```bash
# Backup etcd
ETCDCTL_API=3 etcdctl snapshot save backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key

# Restore etcd
ETCDCTL_API=3 etcdctl snapshot restore backup.db \
  --data-dir=/var/lib/etcd-restore
```

## Security Configuration

### RBAC Setup
```yaml
# Service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default

---
# Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "create", "update", "delete"]

---
# Role binding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: default
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-communication
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web-app
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### Pod Security
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    image: my-app:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    resources:
      limits:
        memory: "512Mi"
        cpu: "500m"
      requests:
        memory: "256Mi"
        cpu: "250m"
```

## Monitoring and Observability

### Prometheus Configuration
```yaml
prometheus:
  enabled: true
  retention: "30d"
  storage_size: "100Gi"
  
  # Scrape configurations
  scrape_configs:
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
```

### Grafana Dashboards
- Cluster overview dashboard
- Node resource utilization
- Pod and container metrics
- Application performance metrics
- Alert status and history

### Log Aggregation
```yaml
logging:
  stack: "loki"  # elasticsearch, loki
  
  # Loki configuration
  loki:
    retention_period: "30d"
    storage_size: "200Gi"
    
  # Log shipping
  promtail:
    enabled: true
    scrape_configs:
      - job_name: containers
        static_configs:
        - targets: [localhost]
          labels:
            job: containerlogs
            __path__: /var/log/containers/*.log
```

## Troubleshooting

### Common Issues

#### Node Issues
```bash
# Check node status
kubectl describe node worker-node-1

# Check kubelet logs
journalctl -u kubelet -f

# Check container runtime
systemctl status containerd
journalctl -u containerd -f

# Check disk space
df -h
docker system df  # if using Docker
crictl images     # if using containerd
```

#### Pod Issues
```bash
# Check pod status
kubectl describe pod my-pod -n namespace

# Check pod logs
kubectl logs my-pod -n namespace -f
kubectl logs my-pod -n namespace --previous

# Debug pod networking
kubectl exec -it my-pod -n namespace -- nslookup kubernetes.default

# Check resource constraints
kubectl top pod my-pod -n namespace
```

#### Cluster Issues
```bash
# Check cluster components
kubectl get componentstatuses

# Check etcd health
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key

# Check API server logs
journalctl -u kube-apiserver -f

# Check network connectivity
kubectl run test-pod --image=busybox -it --rm -- nslookup kubernetes.default
```

#### Certificate Issues
```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew certificates
kubeadm certs renew all

# Restart control plane components
systemctl restart kubelet
```

## Integration with CI/CD

### GitOps with ArgoCD
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-application
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/my-app
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### CI/CD Pipeline Integration
```yaml
# .github/workflows/deploy.yml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Configure kubectl
      uses: azure/k8s-set-context@v1
      with:
        method: kubeconfig
        kubeconfig: ${{ secrets.KUBE_CONFIG }}
        
    - name: Deploy application
      run: |
        kubectl apply -f k8s/
        kubectl rollout status deployment/my-app
```

## Best Practices

### 1. Security
- Regular security updates
- Least privilege access (RBAC)
- Network segmentation
- Image scanning and policies
- Secret management with external providers

### 2. Performance
- Resource requests and limits
- Horizontal Pod Autoscaling (HPA)
- Vertical Pod Autoscaling (VPA)
- Cluster autoscaling
- Efficient image layering

### 3. High Availability
- Multi-zone deployments
- Pod disruption budgets
- Health checks and probes
- Backup and disaster recovery
- Load balancing and traffic management

### 4. Monitoring
- Comprehensive observability
- Proactive alerting
- Performance baselines
- Capacity planning
- SLI/SLO definition

## Support and Documentation

- **Comprehensive Deployment Guide**: [Kubernetes Deployment Guide](../cicd-templates/docs/KUBERNETES_DEPLOYMENT_GUIDE.md)
- **Official Documentation**: https://kubernetes.io/docs/
- **Community Support**: https://kubernetes.slack.com/
- **Best Practices**: https://kubernetes.io/docs/concepts/configuration/overview/

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes in a development cluster
4. Submit a pull request
5. Update documentation

## License

This automation is provided under the same license as the main project.