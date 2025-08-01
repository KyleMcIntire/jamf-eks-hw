#!/bin/bash
# Cost monitoring script

echo "=== AWS Cost Monitor ==="
echo "Current AWS resources that will incur costs:"
echo ""

# Check EKS clusters
echo "EKS Clusters:"
aws eks list-clusters \
  --query 'clusters[]' \
  --output table \
  --no-cli-pager

# Check EC2 instances
echo -e "\nEC2 Instances:"
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --no-cli-pager

# Check Load Balancers
echo -e "\nLoad Balancers:"
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code]' \
  --output table \
  --no-cli-pager

# Check EBS volumes
echo -e "\nEBS Volumes:"
aws ec2 describe-volumes \
  --query 'Volumes[?State==`in-use`].[VolumeId,Size,VolumeType,State]' \
  --output table \
  --no-cli-pager
