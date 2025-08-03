# Metrics Server Helm Configuration

This directory contains Helm values files for deploying the Kubernetes Metrics Server using the official chart.

## Prerequisites

1. Add the metrics-server Helm repository:

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
```

## Deployment

### Development Environment (kind, minikube, etc.)

For development clusters that use self-signed certificates:

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --create-namespace \
  -f helm/metrics-server/values-dev.yaml
```

### Production Environment (AWS EKS, etc.)

For production clusters with proper TLS certificates:

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --create-namespace \
  -f helm/metrics-server/values-prod.yaml
```

## Verification

After installation, verify that metrics are working:

```bash
# Check pod status
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

# Test node metrics
kubectl top nodes

# Test pod metrics
kubectl top pods -A
```

## Configuration Differences

| Setting       | Development                         | Production    |
| ------------- | ----------------------------------- | ------------- |
| TLS Mode      | Insecure (`--kubelet-insecure-tls`) | Secure        |
| Replicas      | 1                                   | 2             |
| Resources     | Lower limits                        | Higher limits |
| PDB           | Disabled                            | Enabled       |
| Anti-affinity | None                                | Preferred     |
| Tolerations   | Control plane tolerations           | None          |

## Troubleshooting

### Common Issues

1. **CrashLoopBackOff with TLS errors**: Use development values for local clusters
2. **No metrics available**: Wait 1-2 minutes after installation
3. **Connection refused**: Check that the secure port matches the container port

### Debug Commands

```bash
# Check logs
kubectl logs -l app.kubernetes.io/name=metrics-server -n kube-system

# Describe deployment
kubectl describe deployment metrics-server -n kube-system

# Check events
kubectl get events --field-selector involvedObject.name=metrics-server -n kube-system
```