# AWS EKS WordPress Deployment - Cost Estimate

## Overview
This document provides cost estimates for the WordPress deployment on AWS EKS in the demo environment (us-east-2 region).

## Infrastructure Configuration
- **EKS Cluster**: jamf-demo-cluster (Kubernetes 1.31)
- **Node Group**: 1x t3.small instance (2 vCPU, 2GB RAM)
- **Storage**: 50GB gp3 EBS volume
- **Network**: Single NAT Gateway (cost-optimized)
- **Region**: us-east-2 (Ohio)

## Hourly Cost Breakdown

| Component | Cost/Hour | Monthly Cost | Percentage |
|-----------|-----------|--------------|------------|
| EKS Control Plane | $0.10 | $73.00 | 54% |
| EC2 Instance (t3.small) | $0.0208 | $15.18 | 12% |
| NAT Gateway | $0.045 | $32.85 | 23% |
| EBS Storage (50GB gp3) | $0.0040 | $2.92 | 2% |
| Data Transfer | $0.005-0.015 | $3.65-10.95 | 9% |

## Total Estimated Costs

### Hourly: $0.175 - $0.185
### Monthly: $125 - $135

## Cost Optimization Features

### Already Implemented
- **Single NAT Gateway**: Using one NAT gateway instead of per-AZ deployment saves ~$65/month
- **t3.small Instances**: Burstable performance instances for cost efficiency
- **No KMS Encryption**: Using default encryption to avoid additional KMS costs
- **Minimal Node Count**: Starting with 1 node, auto-scaling up to 3 as needed
- **gp3 Storage**: More cost-effective than gp2 with better baseline performance

### Additional Cost Savings Options
- **t3.micro**: Could reduce EC2 costs by ~50% but may impact WordPress performance
- **Spot Instances**: Could reduce EC2 costs by 60-90% but adds complexity
- **Reserved Instances**: 1-year commitment could save ~30% on EC2 costs
- **Scheduled Scaling**: Scale down to 0 nodes during off-hours (demo only)

## Cost Comparison

### Alternative Instance Types
| Instance Type | vCPU | RAM | Cost/Hour | Monthly Cost | Use Case |
|---------------|------|-----|-----------|--------------|----------|
| t3.micro | 1 | 1GB | $0.0104 | $7.59 | Minimal demo |
| t3.small | 2 | 2GB | $0.0208 | $15.18 | **Current choice** |
| t3.medium | 2 | 4GB | $0.0416 | $30.37 | Production-like |

## Monitoring Recommendations
- Set up AWS Cost Alerts at $100 and $150 monthly thresholds
- Monitor EKS cluster utilization to optimize node sizing
- Review NAT Gateway data transfer costs monthly
- Consider AWS Cost Explorer for detailed cost analysis

## Notes
- Costs are estimates based on us-east-2 pricing as of January 2025
- Actual costs may vary based on usage patterns and data transfer
- Demo environment should be terminated when not in use to minimize costs
- WordPress traffic and plugin usage will affect data transfer costs