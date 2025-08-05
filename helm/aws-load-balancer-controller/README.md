# AWS Load Balancer Controller Helm Configuration

This directory contains Helm values for deploying the AWS Load Balancer Controller on Amazon EKS using the official chart.

## Prerequisites

1. **EKS Cluster**: Running Amazon EKS cluster
2. **IAM Role**: IAM role for service account (IRSA) with appropriate permissions
3. **AWS CLI**: Configured with appropriate permissions
4. **kubectl**: Configured to connect to your EKS cluster
5. **Helm**: Version 3.x installed

### Required IAM Permissions

The IAM role needs the following AWS managed policy:
- `AWSLoadBalancerControllerIAMPolicy`

This is created via the terraform deployment.

Or create a custom policy with the permissions from: https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

## Setup Instructions

### 1. Add Helm Repository

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

### 2. Apply CRDs

```bash
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
```

### 3. Get Required Information

You'll need to gather the following information:

```bash
# Get cluster name from current context
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
echo "Cluster Name: $CLUSTER_NAME"

# Get AWS region from current context  
AWS_REGION=$(kubectl config current-context | cut -d':' -f4)
echo "AWS Region: $AWS_REGION"

# Get VPC ID for the cluster
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo "VPC ID: $VPC_ID"

# Get IAM role ARN (if using Terraform)
cd terraform/environments/demo
ROLE_ARN=$(terraform output -raw aws_load_balancer_controller_role_arn)
echo "IAM Role ARN: $ROLE_ARN"
cd -
```

### 4. Install with Custom Values

Instead of modifying the values file, pass the required values as arguments to the helm install command using the variables from step 3:

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set region="$AWS_REGION" \
  --set vpcId="$VPC_ID" \
  --set-string serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN"
```

This uses the environment variables set in the previous step to automatically configure the controller with your cluster's specific values.

### 5. Verify Installation

The installation from step 4 will automatically wait for the deployment to be ready. You can verify it's working with the commands in the next section.

## Verification

After installation, verify the controller is running:

```bash
# Check deployment status
kubectl get deployment -n kube-system aws-load-balancer-controller

# Check pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Usage Examples

### Basic ALB Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

### HTTPS with SSL Certificate

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: https-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/cert-id
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

### Internal Load Balancer

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: internal.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: internal-service
            port:
              number: 80
```

## Troubleshooting

### Common Issues

1. **Controller not starting**: Check IAM role permissions and annotations
2. **Ingress not creating ALB**: Verify ingress class and annotations
3. **Target registration failures**: Check security groups and subnet tags

### Debug Commands

```bash
# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Describe ingress for events
kubectl describe ingress <ingress-name>

# Check service account
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system

# Verify IAM role assumption
kubectl get serviceaccount aws-load-balancer-controller -n kube-system -o yaml
```

### Required Subnet Tags

Ensure your subnets are properly tagged:

**Public subnets** (for internet-facing load balancers):
```
kubernetes.io/role/elb = 1
```

**Private subnets** (for internal load balancers):
```
kubernetes.io/role/internal-elb = 1
```

## Uninstallation

To remove the AWS Load Balancer Controller:

```bash
# Uninstall Helm release
helm uninstall aws-load-balancer-controller -n kube-system

# Remove CRDs (optional - this will remove all ALB resources)
kubectl delete -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
```

## References

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Helm Chart Repository](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)
- [IAM Policy Requirements](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json)