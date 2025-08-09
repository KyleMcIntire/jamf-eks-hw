# AWS EKS WordPress Deployment - Cost Estimate

## Overview

This document provides cost estimates for the WordPress deployment on AWS EKS in the demo environment (us-east-2 region).

## Infrastructure Configuration

- **EKS Cluster**: jamf-demo-cluster (Kubernetes 1.31)
- **Node Group**: 1-4x t3.large instances (2 vCPU, 8GB RAM)
- **Storage**: 50GB gp3 EBS volume per node + 10GB gp2 for WordPress/MySQL
- **Network**: Single NAT Gateway (cost-optimized)
- **Region**: us-east-2 (Ohio)
- **WordPress**: 2-20 replicas with HPA, 5GB persistent storage
- **MySQL**: MariaDB 10.11 with 5GB persistent storage

## Hourly Cost Breakdown

| Component                  | Cost/Hour    | Monthly Cost | Percentage |
| -------------------------- | ------------ | ------------ | ---------- |
| EKS Control Plane          | $0.10        | $73.00       | 46%        |
| EC2 Instance (1x t3.large) | $0.0832      | $60.74       | 38%        |
| NAT Gateway                | $0.045       | $32.85       | 21%        |
| EBS Storage (60GB total)   | $0.0082      | $5.99        | 4%         |
| Data Transfer              | $0.005-0.015 | $3.65-10.95  | 2-7%       |

## Total Estimated Costs

### Hourly: $0.241 - $0.251

### Monthly: $176 - $183

### With Auto-Scaling (2-4 nodes): $300 - $450

## Cost Optimization Features

### Already Implemented

- **Single NAT Gateway**: Using one NAT gateway instead of per-AZ deployment saves ~$65/month
- **t3.large Instances**: Burstable performance instances for cost efficiency
- **No KMS Encryption**: Using default encryption to avoid additional KMS costs
- **Auto-Scaling**: Starting with 1 node, scaling 1-4 based on demand
- **gp3 Storage**: More cost-effective than gp2 for node storage (50GB per node)
- **Efficient WordPress Config**: 2-20 pod HPA with resource limits (200m CPU, 512Mi RAM)
- **MariaDB over MySQL**: Lighter database footprint

### Additional Cost Savings Options

- **t3.micro**: Could reduce EC2 costs by ~50% but may impact WordPress performance
- **Spot Instances**: Could reduce EC2 costs by 60-90% but adds complexity
- **Reserved Instances**: 1-year commitment could save ~30% on EC2 costs
- **Scheduled Scaling**: Scale down to 0 nodes during off-hours (demo only)

## Cost Comparison

### Alternative Instance Types

| Instance Type | vCPU | RAM  | Cost/Hour | Monthly Cost | Use Case                |
| ------------- | ---- | ---- | --------- | ------------ | ----------------------- |
| t3.small      | 2    | 2GB  | $0.0208   | $15.18       | Minimal demo            |
| t3.medium     | 2    | 4GB  | $0.0416   | $30.37       | Light production        |
| t3.large      | 2    | 8GB  | $0.0832   | $60.74       | **Current choice**      |
| t3.xlarge     | 4    | 16GB | $0.1664   | $121.47      | High-traffic production |

## Monitoring Recommendations

- Set up AWS Cost Alerts at $200 and $400 monthly thresholds (adjusted for t3.large)
- Monitor EKS cluster utilization to optimize node sizing
- Review NAT Gateway data transfer costs monthly
- Consider AWS Cost Explorer for detailed cost analysis
- Use AWS Cost Anomaly Detection for unexpected cost spikes
- Monitor HPA scaling patterns to optimize min/max replica counts
- Track WordPress pod resource usage vs limits (200m CPU, 512Mi RAM)

## Notes

- Costs are estimates based on us-east-2 pricing as of February 2025
- Actual costs may vary based on usage patterns and data transfer
- Demo environment should be terminated when not in use to minimize costs
- WordPress traffic and plugin usage will affect data transfer costs
- Prices include standard AWS support tier (no additional cost)
- HPA configuration allows scaling from 2-20 WordPress pods based on CPU/memory usage
- Storage costs include both node storage (gp3) and application storage (gp2)
- Load testing may trigger auto-scaling, significantly increasing costs temporarily
