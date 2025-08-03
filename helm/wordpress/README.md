# WordPress Helm Chart

This Helm chart deploys a WordPress application with MySQL database, including horizontal pod autoscaling (HPA), resource quotas, and persistent storage.

## Overview

The chart creates:
- WordPress deployment with configurable replicas
- MySQL/MariaDB database deployment
- Persistent volumes for both WordPress and MySQL
- Horizontal Pod Autoscaler (HPA) for WordPress
- Resource quotas and limit ranges
- Kubernetes secrets for passwords
- Services for internal and external access

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- Metrics Server (for HPA functionality)
- Storage class available for persistent volumes

## Installation

### Quick Start (Kind/Local Development)

```bash
# Install with kind-specific values
helm install wordpress . -f values-dev.yaml
```

### EKS Demo Installation

```bash
# Install with EKS demo values (optimized for load testing)
helm install wordpress . -f values-eks-demo.yaml -n wordpress-demo --create-namespace
```

### Production Installation

```bash
# Install with production values
helm install wordpress . -f values-prod.yaml
```

### Custom Installation

```bash
# Install with custom values
helm install wordpress . \
  --set wordpress.password=mypassword \
  --set mysql.password=mysqlpassword \
  --set service.type=LoadBalancer
```

## Configuration

### Values Files

| File                   | Purpose                     | Environment        |
| ---------------------- | --------------------------- | ------------------ |
| `values.yaml`          | Default production values   | Production/AWS EKS |
| `values-eks-demo.yaml` | EKS demo with load testing  | AWS EKS Demo       |
| `values-kind.yaml`     | Local development overrides | Kind/Minikube      |

### Key Configuration Options

#### WordPress Configuration

```yaml
wordpress:
  image:
    repository: wordpress
    tag: "6.4.2-apache"
  
  # Admin user settings
  username: admin
  password: ""  # Auto-generated if empty
  email: admin@example.com
  
  # Resource limits
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  
  # Persistent storage
  persistence:
    enabled: true
    storageClass: "gp3-encrypted"
    size: 10Gi
```

#### MySQL Configuration

```yaml
mysql:
  image:
    repository: mysql
    tag: "8.0"
  
  # Database settings
  database: wordpress
  user: wordpress
  password: ""  # Auto-generated if empty
  
  # Resource limits
  resources:
    requests:
      cpu: "250m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

#### Autoscaling Configuration

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

#### Service Configuration

```yaml
service:
  type: LoadBalancer  # or NodePort, ClusterIP
  port: 80
  httpsPort: 443
```

## Environment-Specific Configurations

### Kind/Local Development (`values-kind.yaml`)

- Uses `standard` storage class (kind default)
- NodePort service for easy local access
- Lower resource requests and limits
- MariaDB instead of MySQL for better compatibility
- Relaxed resource quotas

### EKS Demo (`values-eks-demo.yaml`)

- Uses `gp2` storage class (AWS EKS default)
- LoadBalancer service (requires AWS Load Balancer Controller)
- Optimized for load testing and HPA demonstration
- Resource quotas allow scaling to 5 pods
- MariaDB for lighter resource usage
- Includes load testing documentation

### Production (`values.yaml`)

- Uses `gp3-encrypted` storage class (AWS EKS)
- LoadBalancer service with SSL termination
- Higher resource requests and limits
- Production-grade MySQL
- Strict resource quotas and security policies

## Horizontal Pod Autoscaler (HPA)

The chart includes HPA configuration that automatically scales WordPress pods based on CPU and memory usage.

### HPA Behavior

- **Scale Up**: When CPU > 70% OR memory > 80%
- **Scale Down**: When both CPU < 70% AND memory < 80%
- **Min Replicas**: 2 (configurable)
- **Max Replicas**: 10 (configurable)
- **Scale Down Delay**: ~5 minutes (Kubernetes default)

### Testing HPA

Use the provided load testing script (requires `values-eks-demo.yaml` configuration):

```bash
# Show current status
./scripts/load-test-demo.sh status

# Start load test (triggers scale-up)
./scripts/load-test-demo.sh start

# Monitor scaling in real-time
kubectl get hpa -n wordpress-demo -w

# Stop load test (triggers scale-down after ~5 minutes)
./scripts/load-test-demo.sh stop
```

#### EKS Demo Load Test Configuration

The `values-eks-demo.yaml` file is specifically configured for effective load testing:

- **Max Replicas**: 5 (allows visible scaling)
- **Resource Quota**: 4Gi memory limit (supports 5 WordPress pods)
- **HPA Targets**: CPU 50%, Memory 60% (sensitive scaling)
- **Load Test**: 5 busybox pods generating continuous HTTP requests

## Resource Management

### Resource Quotas

The chart creates namespace-level resource quotas:

```yaml
resourceQuota:
  requests:
    cpu: "4"
    memory: 8Gi
  limits:
    cpu: "8"
    memory: 16Gi
  persistentvolumeclaims: "10"
  pods: "20"
```

### Limit Ranges

Default resource limits for pods without explicit resource specifications:

```yaml
limitRange:
  default:
    cpu: "500m"
    memory: "512Mi"
  defaultRequest:
    cpu: "100m"
    memory: "128Mi"
```

## Persistent Storage

### WordPress Storage
- **Path**: `/var/www/html`
- **Default Size**: 10Gi (production), 5Gi (kind)
- **Access Mode**: ReadWriteOnce
- **Contains**: WordPress files, themes, plugins, uploads

### MySQL Storage
- **Path**: `/var/lib/mysql`
- **Default Size**: 20Gi (production), 5Gi (kind)
- **Access Mode**: ReadWriteOnce
- **Contains**: MySQL database files

## Security

### Password Management

Passwords are automatically generated and stored in Kubernetes secrets:

- **WordPress admin password**: `wordpress-secrets/wordpress-password`
- **MySQL root password**: `wordpress-secrets/mysql-root-password`
- **MySQL user password**: `wordpress-secrets/mysql-password`

### Pod Security

The chart includes pod security standards:

```yaml
security:
  podSecurityStandard:
    enforce: baseline
    audit: restricted
    warn: restricted
```

## Monitoring and Troubleshooting

### Check Deployment Status

```bash
# Check all resources
kubectl get all -n wordpress-demo

# Check HPA status
kubectl get hpa -n wordpress-demo

# Check resource usage
kubectl top pods -n wordpress-demo
```

### View Logs

```bash
# WordPress logs
kubectl logs -l app=wordpress -n wordpress-demo

# MySQL logs
kubectl logs -l app=mysql -n wordpress-demo

# Follow logs
kubectl logs -f deployment/wordpress -n wordpress-demo
```

### Common Issues

#### HPA Not Scaling

1. **Check Metrics Server**: `kubectl get pods -n kube-system | grep metrics-server`
2. **Check Resource Requests**: Ensure pods have CPU/memory requests defined
3. **Check Resource Usage**: `kubectl top pods -n wordpress-demo`

#### Pods Stuck in Pending

1. **Check Resource Quotas**: `kubectl describe quota -n wordpress-demo`
2. **Check Storage**: `kubectl get pvc -n wordpress-demo`
3. **Check Node Resources**: `kubectl describe nodes`

#### Database Connection Issues

1. **Check MySQL Pod**: `kubectl get pods -l app=mysql -n wordpress-demo`
2. **Check Service**: `kubectl get svc wordpress-mysql -n wordpress-demo`
3. **Check Secrets**: `kubectl get secrets -n wordpress-demo`

## Upgrading

### Upgrade WordPress

```bash
# Upgrade with new image version
helm upgrade wordpress . -f values-kind.yaml \
  --set wordpress.image.tag=6.5.0-apache \
  --namespace wordpress-demo
```

### Upgrade Configuration

```bash
# Upgrade with new values
helm upgrade wordpress . -f values-kind.yaml \
  --namespace wordpress-demo
```

## Uninstallation

```bash
# Uninstall release
helm uninstall wordpress -n wordpress-demo

# Optional: Delete persistent volumes
kubectl delete pvc -l app.kubernetes.io/instance=wordpress -n wordpress-demo

# Optional: Delete namespace
kubectl delete namespace wordpress-demo
```

## Development

### Chart Structure

```
helm/wordpress/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values (production)
├── values-kind.yaml        # Kind/local overrides
├── templates/
│   ├── deployment.yaml     # WordPress deployment
│   ├── mysql-deployment.yaml # MySQL deployment
│   ├── service.yaml        # Services
│   ├── pvc.yaml           # Persistent volume claims
│   ├── secrets.yaml       # Password secrets
│   ├── hpa.yaml           # Horizontal pod autoscaler
│   ├── resource-quota.yaml # Resource quotas
│   ├── limit-range.yaml   # Limit ranges
│   └── _helpers.tpl       # Template helpers
└── README.md              # This file
```

### Testing Changes

```bash
# Lint chart
helm lint .

# Template and review
helm template wordpress . -f values-kind.yaml

# Dry run
helm install wordpress . -f values-kind.yaml --dry-run --debug
```

## Examples

### Accessing WordPress

After installation, get the service details:

```bash
# For NodePort (kind)
kubectl get svc wordpress -n wordpress-demo
# Access via http://localhost:<nodeport>

# For LoadBalancer (production)
kubectl get svc wordpress -n wordpress-demo
# Access via external IP
```

### Scaling Manually

```bash
# Scale WordPress deployment
kubectl scale deployment wordpress --replicas=5 -n wordpress-demo

# Note: HPA will override manual scaling
```

### Backup Database

```bash
# Create database backup
kubectl exec -it deployment/wordpress-mysql -n wordpress-demo -- \
  mysqldump -u root -p wordpress > wordpress-backup.sql
```

## References

- [WordPress Docker Image](https://hub.docker.com/_/wordpress)
- [MySQL Docker Image](https://hub.docker.com/_/mysql)
- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)