# Infrastructure Setup

This directory contains Terraform configuration to deploy an EKS cluster with ArgoCD for running the Fiber application.

## Architecture

- **EKS Cluster**: Managed Kubernetes cluster on AWS
- **VPC**: Custom VPC with public and private subnets across 3 AZs
- **Node Groups**: Managed node groups with auto-scaling
- **ArgoCD**: GitOps continuous delivery tool installed via Helm
- **ECR**: Container registry for storing application images
- **Load Balancer**: Network Load Balancer for ArgoCD access

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **kubectl** for cluster interaction
4. **helm** for package management (optional)

### Required AWS Permissions

Your AWS user/role needs permissions for:
- EKS cluster creation and management
- VPC, subnet, and security group management
- IAM role and policy management
- ECR repository management
- Load balancer creation

## Quick Start

### 1. Initialize Terraform

```bash
cd infra
terraform init
```

### 2. Review and Customize Variables

Edit `terraform.tfvars` or use command-line variables:

```bash
# terraform.tfvars example
aws_region = "us-east-2"
project_name = "devops-demo"
environment = "dev"
git_repo_url = "https://github.com/psteger/DevOpsDemo2025.git"
```

### 3. Plan and Apply

```bash
# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

**Note**: Initial deployment takes approximately 15-20 minutes.

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name devops-demo-eks-cluster
```

### 5. Access ArgoCD

Get the ArgoCD server URL and admin password:

```bash
terraform output argocd_server_url
terraform output argocd_initial_admin_password
```

Login credentials:
- **Username**: `admin`
- **Password**: Use the output from the command above

## Key Resources Created

### EKS Cluster
- **Cluster Name**: `{project_name}-eks-cluster`
- **Version**: Kubernetes 1.34 (configurable)
- **Node Groups**: t3.medium instances (configurable)
- **Networking**: Private subnets with NAT gateway

### ArgoCD
- **Namespace**: `argocd`
- **Access**: LoadBalancer service (NLB)
- **Application**: Pre-configured to deploy from the `/k8s` directory

### ECR Repository
- **Repository**: `{project_name}/fiber-app`
- **Features**: Image scanning, lifecycle policies

## Application Deployment

ArgoCD is configured to automatically deploy applications from the `/k8s` directory in your repository. To deploy the Fiber application:

1. Create Kubernetes manifests in `/k8s` directory
2. Push to your Git repository
3. ArgoCD will automatically sync and deploy

### Example Kubernetes Manifests Structure
```
k8s/
├── deployment.yaml
├── service.yaml
└── ingress.yaml (optional)
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-west-2` |
| `project_name` | Project name for resources | `devops-demo` |
| `kubernetes_version` | EKS cluster version | `1.34` |
| `node_instance_types` | EC2 instance types for nodes | `["t3.medium"]` |
| `node_group_desired_size` | Desired number of nodes | `2` |
| `git_repo_url` | Git repository for ArgoCD | Current repo |

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the EKS cluster and any deployed applications.

## Troubleshooting

### Common Issues

1. **AWS Permissions**: Ensure your AWS credentials have sufficient permissions
2. **Region Availability**: Some regions may not support all EKS features
3. **Resource Limits**: Check your AWS account limits for EKS clusters and Load Balancers

### Useful Commands

```bash
# Check EKS cluster status
aws eks describe-cluster --name devops-demo-eks-cluster

# List ArgoCD applications
kubectl get applications -n argocd

# Check node status
kubectl get nodes

# ArgoCD CLI login
argocd login <ARGOCD_SERVER_URL> --username admin --password <PASSWORD>
```

## Monitoring and Logging

The setup includes basic monitoring through:
- EKS CloudWatch logging (optional, can be enabled)
- ArgoCD application metrics
- ECR image scanning results

For production environments, consider adding:
- Prometheus and Grafana for metrics
- ELK stack for centralized logging
- AWS CloudTrail for audit logging