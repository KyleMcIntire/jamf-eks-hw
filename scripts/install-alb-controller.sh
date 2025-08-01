#!/bin/bash
# AWS Load Balancer Controller Installation Script
# This script installs the AWS Load Balancer Controller for EKS
#
# Usage: ./install-alb-controller.sh
# Cluster name is automatically detected from kubectl context

set -e

echo "=== Installing AWS Load Balancer Controller ==="

# Get cluster name from kubectl context
echo "Detecting cluster name from kubectl context..."
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ]; then
    echo "Error: Could not detect cluster name from kubectl context"
    echo "Please ensure kubectl is configured and connected to your EKS cluster"
    exit 1
fi

echo "Detected cluster name: $CLUSTER_NAME"

# Get AWS region from kubectl context
echo "Detecting AWS region..."
AWS_REGION=$(kubectl config current-context | cut -d':' -f4 2>/dev/null || echo "")

if [ -z "$AWS_REGION" ]; then
    echo "Error: Could not detect AWS region from kubectl context"
    echo "Please ensure kubectl is configured with proper EKS context"
    exit 1
fi

echo "Detected AWS region: $AWS_REGION"

# Get VPC ID for the cluster
echo "Getting VPC ID for cluster..."
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query "cluster.resourcesVpcConfig.vpcId" --output text 2>/dev/null || echo "")

if [ -z "$VPC_ID" ]; then
    echo "Error: Could not get VPC ID for cluster $CLUSTER_NAME"
    echo "Please ensure AWS CLI is configured and you have permissions to describe the EKS cluster"
    exit 1
fi

echo "Detected VPC ID: $VPC_ID"

echo "Installing for cluster: $CLUSTER_NAME in region: $AWS_REGION"

# Add Helm repository
echo "Adding EKS Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create IAM service account for AWS Load Balancer Controller
echo "Creating IAM service account..."
eksctl create iamserviceaccount \
  --cluster="$CLUSTER_NAME" \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve \
  --override-existing-serviceaccounts \
  --region="$AWS_REGION"

# Apply CRDs
echo "Applying AWS Load Balancer Controller CRDs..."
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

# Install AWS Load Balancer Controller
echo "Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region="$AWS_REGION" \
  --set vpcId="$VPC_ID" \
  --wait \
  --timeout=5m

# Verify installation
echo "Verifying installation..."
kubectl get deployment -n kube-system aws-load-balancer-controller

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=Available deployment/aws-load-balancer-controller -n kube-system --timeout=300s

echo "✅ AWS Load Balancer Controller installed successfully!"
echo ""
echo "You can now create Ingress resources with the following annotation:"
echo "  kubernetes.io/ingress.class: alb"
echo ""
echo "Example Ingress resource:"
echo "  apiVersion: networking.k8s.io/v1"
echo "  kind: Ingress"
echo "  metadata:"
echo "    annotations:"
echo "      kubernetes.io/ingress.class: alb"
echo "      alb.ingress.kubernetes.io/scheme: internet-facing"
echo "      alb.ingress.kubernetes.io/target-type: ip"