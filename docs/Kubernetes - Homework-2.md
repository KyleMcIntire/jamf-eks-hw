# Kubernetes Assignment - Jamf DevOps Engineer II (Kubernetes) Technical Interview

- [Kubernetes Assignment - Jamf DevOps Engineer II (Kubernetes) Technical Interview](#kubernetes-assignment---jamf-devops-engineer-ii-kubernetes-technical-interview)
  - [Overview - What We Are Looking For](#overview---what-we-are-looking-for)
  - [Alternate Options](#alternate-options)
  - [Task Outline](#task-outline)
  - [Demonstration of Work](#demonstration-of-work)
    - [What problems did you encounter in this work, and how did you overcome them?](#what-problems-did-you-encounter-in-this-work-and-how-did-you-overcome-them)
    - [What resources did you use to complete the work, and how did you research any necessary information?](#what-resources-did-you-use-to-complete-the-work-and-how-did-you-research-any-necessary-information)
    - [How would you configure your application for high availability?](#how-would-you-configure-your-application-for-high-availability)
    - [What is the difference, if any, between deploying this configuration with Terraform and Helm versus a plain Kubernetes manifest?](#what-is-the-difference-if-any-between-deploying-this-configuration-with-terraform-and-helm-versus-a-plain-kubernetes-manifest)
    - [If any of the tools you used in this work are new to you, what other similar tools have you used in the past, and what differences could you describe between our tooling and your past tools?](#if-any-of-the-tools-you-used-in-this-work-are-new-to-you-what-other-similar-tools-have-you-used-in-the-past-and-what-differences-could-you-describe-between-our-tooling-and-your-past-tools)
    - [Are there any security vulnerabilities you see in your deployment? What steps would you take to harden this deployment if you were running it in a large enterprise setting?](#are-there-any-security-vulnerabilities-you-see-in-your-deployment-what-steps-would-you-take-to-harden-this-deployment-if-you-were-running-it-in-a-large-enterprise-setting)


## Overview - What We Are Looking For

This task is designed to see how you approach deploying the types of systems that our Kube teams encounter on a regular basis. We appreciate that this interview step takes time and energy, and we thank you for letting us see your best work in action. Please feel free to use supplementary resources, but please share in the work demonstration (see below) what resources you consulted to complete this work. Your problem-solving process is as much a part of this interview stage as is the product you build.

## Alternate Options

Our goal is to see how you approach the following tasks. If you have existing work in a public GitHub that you can share which demonstrates these skills, please feel free to utilize that, although take care that you can address all the competencies outlined below.

## Task Outline

You may use any Kubernetes platform or provider for the following work, however Jamf uses Amazon EKS.

1. Deploy a cluster with at least two nodes: one control plane and at least one worker.

2. Deploy a simple application that has multiple services and components, such as WordPress. Expose the application so that it can be accessed from outside the cluster, such as from a browser or terminal on localhost. Note: if you are running your Kube locally, it does not have to be publicly accessible-- just accessible from your local machine.

3. Define resource limits for the namespace. You can determine what these limits should be, but please explain in your show and tell (below) what limits you chose and why you set them where you did, as well as how you would configure this differently for high availability. Configure autoscaling so that the resource limits you defined will trigger scaling pods up and down when appropriate.

4. Once your deployment is finished, create a Terraform configuration and Helm chart which would replicate your deployment.

## Demonstration of Work

We will schedule a one-hour demonstration session with some of our engineering staff. During this session, you can demonstrate your product and explain your process. The first 30 minutes are reserved for you to “show and tell.” Some things that you might include, which are of particular interest to us, are:

### What problems did you encounter in this work, and how did you overcome them?

**Key challenges and solutions:**

1. **Resource Quotas vs HPA Scaling**: The initial resource quotas were too restrictive for effective HPA demonstration. WordPress pods couldn't scale beyond 2 replicas due to memory limits. Resolved by adjusting the resource quotas in `values-eks-demo.yaml` to allow up to 20 pods with 4Gi total memory requests.

2. **Secret Management**: Helm's random password generation was regenerating passwords on every upgrade, breaking WordPress installations. Implemented a lookup-based approach in `templates/secrets.yaml` that preserves existing passwords while generating new ones only for fresh installations.

### What resources did you use to complete the work, and how did you research any necessary information?

**Primary resources used:**

1. **Official Documentation**:
   - [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/) - For cluster configuration and security
   - [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) - For autoscaling configuration
   - [Helm Chart Development Guide](https://helm.sh/docs/chart_template_guide/) - For templating and best practices

2. **Terraform Modules**:
   - [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) - Comprehensive EKS setup
   - [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) - VPC configuration with EKS-specific tags

3. **Community Resources**:
   - [Kubernetes WordPress Tutorial](https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/) - Base deployment patterns
   - AWS EKS Workshop materials for IRSA and add-on configurations
   - GitHub repositories with similar WordPress on EKS implementations for reference

4. **Research Methodology**:
   - Started with official AWS/Kubernetes documentation for foundational understanding
   - Used Terraform module documentation for implementation details
   - Consulted community examples for real-world patterns and troubleshooting
   - Tested configurations in local Kind clusters before EKS deployment

### How would you configure your application for high availability?

**Current demo setup limitations:**

- Single AZ deployment (cost optimization)
- Single MySQL instance (not HA)
- Basic monitoring and alerting

**Production HA configuration would include:**

1. **Multi-AZ Infrastructure**:

   ```hcl
   # Terraform: Deploy across 3 AZs minimum
   azs = ["us-east-2a", "us-east-2b", "us-east-2c"]
   
   # Node groups in multiple AZs
   eks_managed_node_groups = {
     main = {
       subnet_ids = module.vpc.private_subnets  # Spans all AZs
       min_size = 3  # At least one node per AZ
     }
   }
   ```

2. **Database High Availability**:

   ```yaml
   # Replace single MySQL with RDS Multi-AZ
   mysql:
     enabled: false  # Disable in-cluster MySQL
   
   externalDatabase:
     host: "wordpress-db.cluster-xxx.us-east-2.rds.amazonaws.com"
     database: wordpress
     existingSecret: rds-credentials
   ```

3. **Application Resilience**:

   ```yaml
   # Pod anti-affinity to spread across nodes/AZs
   affinity:
     podAntiAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
       - labelSelector:
           matchLabels:
             app: wordpress
         topologyKey: kubernetes.io/hostname
   
   # Pod disruption budget
   podDisruptionBudget:
     enabled: true
     minAvailable: 2
   ```

4. **Storage and Backup**:

   ```yaml
   # Cross-AZ storage with backup
   persistence:
     storageClass: "gp3"  # Upgrade from gp2 for better performance
     size: 50Gi
   
   # Automated backups via Velero or AWS Backup
   ```

5. **Load Balancing and Ingress**:

   ```yaml
   # Application Load Balancer with health checks
   service:
     type: LoadBalancer
     annotations:
       service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
       service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
   ```

### What is the difference, if any, between deploying this configuration with Terraform and Helm versus a plain Kubernetes manifest?

**Terraform + Helm Approach (Current Implementation):**

*Advantages:*

- **Infrastructure as Code**: Terraform manages AWS resources (VPC, EKS, IAM) with state tracking and drift detection
- **Parameterization**: Helm templates allow environment-specific configurations via values files
- **Release Management**: Helm provides upgrade/rollback capabilities with release history
- **Dependency Management**: Clear separation between infrastructure (Terraform) and application (Helm) layers
- **Reusability**: Charts can be shared across environments and teams

*Example deployment:*

```bash
# Infrastructure
terraform apply
# Application  
helm install wordpress . -f values-eks-demo.yaml
```

**Plain Kubernetes Manifests:**

*Advantages:*

- **Transparency**: Direct YAML with no abstraction layers
- **GitOps Friendly**: Better integration with ArgoCD/Flux for declarative deployments
- **Debugging**: Easier to troubleshoot since you see exactly what's deployed
- **No Tool Dependencies**: Only requires kubectl

*Disadvantages:*

- **Manual Value Substitution**: Need tools like Kustomize or manual sed/envsubst for environment differences
- **No Release Management**: Manual tracking of deployments and rollbacks
- **Repetitive Configuration**: Duplicate YAML across environments

**Hybrid Approach Benefits:**
The current implementation gets the best of both worlds - Terraform's infrastructure management with Helm's application templating, while maintaining the option to export to plain manifests when needed:

```bash
# Generate plain manifests from Helm for GitOps
helm template wordpress . -f values-eks-demo.yaml > wordpress-manifests.yaml
```

### If any of the tools you used in this work are new to you, what other similar tools have you used in the past, and what differences could you describe between our tooling and your past tools?

My experience has been with AWS EKS and Helm in the past. These are the tools / technologies I am used to.

### Are there any security vulnerabilities you see in your deployment? What steps would you take to harden this deployment if you were running it in a large enterprise setting?

**Current Security Vulnerabilities:**

1. **Secrets Management**:
   - Kubernetes secrets are only base64 encoded, not encrypted at rest
   - Passwords are generated and stored in cluster without external key management
   - No secret rotation mechanism

2. **Network Security**:
   - No network policies implemented - pods can communicate freely
   - Public subnets allow direct internet access to worker nodes
   - No micro-segmentation between application tiers

3. **Pod Security**:
   - Using "baseline" Pod Security Standards instead of "restricted"
   - Containers running as root in some cases
   - No admission controllers for policy enforcement

4. **Image Security**:
   - Using public container images without vulnerability scanning
   - No image signing or verification
   - Latest/mutable tags instead of immutable digests

5. **Access Control**:
   - Broad RBAC permissions for demo simplicity
   - No audit logging enabled
   - Cluster creator has admin permissions

**Enterprise Hardening Steps:**

1. **Enhanced Secrets Management**:

   ```yaml
   # AWS Secrets Manager integration
   apiVersion: external-secrets.io/v1beta1
   kind: SecretStore
   metadata:
     name: aws-secrets-manager
   spec:
     provider:
       aws:
         service: SecretsManager
         region: us-east-2
         auth:
           secretRef:
             accessKeyID:
               name: awssm-secret
               key: access-key
   ```

2. **Network Policies**:

   ```yaml
   # Deny all by default, allow specific traffic
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: wordpress-netpol
   spec:
     podSelector:
       matchLabels:
         app: wordpress
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: ingress-nginx
       ports:
       - protocol: TCP
         port: 80
     egress:
     - to:
       - podSelector:
           matchLabels:
             app: mysql
       ports:
       - protocol: TCP
         port: 3306
   ```

3. **Pod Security Standards**:

   ```yaml
   # Restricted pod security
   apiVersion: v1
   kind: Namespace
   metadata:
     name: wordpress-prod
     labels:
       pod-security.kubernetes.io/enforce: restricted
       pod-security.kubernetes.io/audit: restricted
       pod-security.kubernetes.io/warn: restricted

   # The restricted policy is the most secure level, requiring things like non-root users, read-only root filesystems, and dropping all capabilities
   ```

4. **Image Security**:

   ```yaml
   # Use private registry with scanning
   image:
     repository: 123456789012.dkr.ecr.us-east-2.amazonaws.com/wordpress
     tag: "6.4.2-apache-hardened"
     digest: "sha256:abc123..."  # Immutable reference
   
   # Image pull policy
   imagePullPolicy: Always
   imagePullSecrets:
   - name: ecr-registry-secret
   ```

5. **RBAC and Audit**:

   ```yaml
   # Minimal RBAC permissions
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: wordpress-role
   rules:
   - apiGroups: [""]
     resources: ["pods", "services"]
     verbs: ["get", "list"]
   - apiGroups: ["apps"]
     resources: ["deployments"]
     verbs: ["get", "list", "patch"]
   ```

6. **Monitoring and Compliance**:

   ```yaml
   # Falco for runtime security
   # OPA Gatekeeper for policy enforcement
   # Prometheus + Grafana for security metrics
   # AWS CloudTrail for API audit logging
   ```

7. **Infrastructure Hardening**:

   ```hcl
   # Private EKS endpoint
   cluster_endpoint_public_access = false
   
   # Encryption at rest
   create_kms_key = true
   cluster_encryption_config = {
     provider_key_arn = aws_kms_key.eks.arn
     resources        = ["secrets"]
   }
   
   # Private worker nodes only
   public_subnets = []  # Remove public subnets for workers
   ```

8. **Backup and Disaster Recovery**:

   ```bash
   # Velero for cluster backups
   # AWS Backup for EBS volumes
   # Cross-region replication for critical data
   ```

These hardening measures would transform the demo deployment into an enterprise-ready, security-compliant WordPress platform suitable for production workloads.
