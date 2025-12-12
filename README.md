# DevOpsDemo2025

A cloud-native microservice demonstration showcasing modern DevOps practices with Go, Kubernetes, Terraform, and GitOps.

## Overview

This project deploys a lightweight Go REST API to AWS EKS using Infrastructure-as-Code (Terraform) and GitOps (ArgoCD). It demonstrates production-ready patterns for containerization, orchestration, and automated deployments.

## Technologies Used

| Component | Technology | Purpose |
|-----------|------------|---------|
| Application | Go 1.25 + Fiber v2 | High-performance REST API |
| Containerization | Docker (multi-stage) | Optimized, secure images |
| Orchestration | Kubernetes (AWS EKS 1.31) | Container management |
| Infrastructure | Terraform | Infrastructure-as-Code |
| GitOps | ArgoCD | Automated continuous deployment |
| Container Registry | AWS ECR | Private image storage |
| Load Balancing | AWS Classic Load Balancer | External traffic routing |
| Networking | AWS VPC | Isolated network environment |

## Architecture

```
                                    AWS Cloud (us-east-2)
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                           VPC (10.0.0.0/16)                             │   │
│   │                                                                         │   │
│   │   ┌─────────────────────┐       ┌─────────────────────────────────┐     │   │
│   │   │   Public Subnets    │       │       Private Subnets           │     │   │
│   │   │   (3 AZs)           │       │       (3 AZs)                   │     │   │
│   │   │                     │       │                                 │     │   │
│   │   │  ┌───────────────┐  │       │  ┌───────────────────────────┐  │     │   │
│   │   │  │ Load Balancer │◄─┼───────┼──┤     EKS Node Group        │  │     │   │
│   │   │  └───────┬───────┘  │       │  │     (t3.medium x2)        │  │     │   │
│   │   │          │          │       │  │                           │  │     │   │
│   │   │          │          │       │  │  ┌─────────────────────┐  │  │     │   │
│   │   │  ┌───────┴───────┐  │       │  │  │   fiber-app Pod 1   │  │  │     │   │
│   │   │  │  NAT Gateway  │  │       │  │  │   (Port 8080)       │  │  │     │   │
│   │   │  └───────────────┘  │       │  │  └─────────────────────┘  │  │     │   │
│   │   │                     │       │  │  ┌─────────────────────┐  │  │     │   │
│   │   │                     │       │  │  │   fiber-app Pod 2   │  │  │     │   │
│   │   │                     │       │  │  │   (Port 8080)       │  │  │     │   │
│   │   │                     │       │  │  └─────────────────────┘  │  │     │   │
│   │   │                     │       │  └───────────────────────────┘  │     │   │
│   │   └─────────────────────┘       └─────────────────────────────────┘     │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────────┐      │
│   │  EKS Control │    │    ArgoCD    │    │         ECR Repository       │      │
│   │    Plane     │    │   (GitOps)   │    │   devops-demo/fiber-app      │      │
│   └──────────────┘    └──────────────┘    └──────────────────────────────┘      │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

When a user makes a request to the application:

```
1. Internet Request
        │
        ▼
2. AWS Load Balancer (Port 80)
   - Receives incoming HTTP traffic
   - Performs health checks against /healthz
   - Distributes traffic across healthy pods
        │
        ▼
3. Kubernetes Service (fiber-app-service)
   - Routes traffic to pod endpoints
   - Load balances across replicas
        │
        ▼
4. Application Pod (Port 8080)
   - Fiber framework processes request
   - Routes to appropriate handler:
     • /healthz  → Health check response
     • /readyz   → Readiness check response
     • /api/message → API response with timestamp
        │
        ▼
5. JSON Response returned to user
   Example: {"message": "Automate all the things!", "timestamp": 1733968234}
```

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| AWS CLI | v2.x | AWS authentication and ECR access |
| Terraform | >= 1.0 | Infrastructure provisioning |
| kubectl | >= 1.28 | Kubernetes cluster management |
| Docker | >= 20.x | Container image building |
| Go | 1.25 | Local development (optional) |

### AWS Requirements

1. **AWS Account** with appropriate permissions
2. **IAM User/Role** with the following policies:
   - `AmazonEKSClusterPolicy`
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess` (for IRSA setup)
   - `ElasticLoadBalancingFullAccess`

3. **AWS CLI configured**:
   ```bash
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (us-east-2)
   ```

### Cost Considerations

Running this infrastructure incurs AWS charges for:
- EKS cluster (~$0.10/hour)
- EC2 instances (2x t3.medium ~$0.08/hour)
- NAT Gateway (~$0.045/hour + data)
- Load Balancer (~$0.025/hour)

**Estimated cost**: ~$6-8/day when running

## Deployment Guide

### Step 1: Clone the Repository

```bash
git clone https://github.com/psteger/DevOpsDemo2025.git
cd DevOpsDemo2025
```

### Step 2: Deploy Infrastructure with Terraform

```bash
cd infra

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure (takes 15-20 minutes)
terraform apply
```

After completion, note the outputs:
- `argocd_server_url` - ArgoCD web UI URL
- `argocd_admin_password` - Command to retrieve admin password
- `ecr_repository_url` - ECR image repository URL
- `configure_kubectl` - Command to configure kubectl

### Step 3: Configure kubectl

```bash
# Run the command from Terraform output
aws eks update-kubeconfig --region us-east-2 --name devops-demo-dev
```

Verify connection:
```bash
kubectl get nodes
```

### Step 4: Build and Push Application Image

```bash
# Authenticate Docker with ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 246314649600.dkr.ecr.us-east-2.amazonaws.com

# Build and push image
cd app
docker build -t 246314649600.dkr.ecr.us-east-2.amazonaws.com/devops-demo/fiber-app:latest .
docker push 246314649600.dkr.ecr.us-east-2.amazonaws.com/devops-demo/fiber-app:latest
```

Or use the provided script:
```bash
./build-and-push.sh
```

### Step 5: Deploy ArgoCD Application

```bash
kubectl apply -f infra/argocd-application.yaml
```

This configures ArgoCD to:
- Monitor the `k8s/` directory in the Git repository
- Automatically sync changes to the cluster
- Self-heal if resources drift from desired state

### Step 6: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n fiber-app

# Get the Load Balancer URL
kubectl get svc -n fiber-app
```

Wait for `EXTERNAL-IP` to be assigned (1-2 minutes).

### Step 7: Test the Application

```bash
# Health check
curl http://<EXTERNAL-IP>/healthz

# API endpoint
curl http://<EXTERNAL-IP>/api/message
```

Expected response:
```json
{"message": "Automate all the things!", "timestamp": 1733968234}
```

## API Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/healthz` | GET | Liveness probe | `200 OK` |
| `/readyz` | GET | Readiness probe | `200 OK` |
| `/api/message` | GET | Main API endpoint | JSON with message and timestamp |

## Project Structure

```
DevOpsDemo2025/
├── app/                          # Go application
│   ├── main.go                   # Entry point and routing
│   ├── handlers.go               # HTTP handlers
│   ├── handlers_test.go          # Unit tests
│   ├── Dockerfile                # Multi-stage build
│   ├── go.mod                    # Go module definition
│   └── go.sum                    # Dependency checksums
│
├── infra/                        # Terraform infrastructure
│   ├── main.tf                   # Provider configuration
│   ├── eks.tf                    # EKS cluster and VPC
│   ├── argocd.tf                 # ArgoCD and ECR setup
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   └── argocd-application.yaml   # ArgoCD app manifest
│
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml            # fiber-app namespace
│   ├── deployment.yaml           # Application deployment
│   ├── service.yaml              # LoadBalancer service
│   └── ingress.yaml              # ALB ingress (optional)
│
├── build-and-push.sh             # Docker build script
├── CLAUDE.md                     # Development guide
└── README.md                     # This file
```

## GitOps Workflow

Once deployed, the GitOps workflow operates as follows:

```
Developer pushes to main branch
            │
            ▼
   ArgoCD detects changes
   (polls every 3 minutes)
            │
            ▼
   Compares Git state vs Cluster state
            │
            ▼
   Auto-syncs differences
   - Creates/updates resources
   - Prunes removed resources
            │
            ▼
   Application updated in cluster
```

To make changes:
1. Edit files in `k8s/` directory
2. Commit and push to main branch
3. ArgoCD automatically deploys changes

## Accessing ArgoCD

```bash
# Get ArgoCD URL
echo $(terraform -chdir=infra output -raw argocd_server_url)

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Login with:
- Username: `admin`
- Password: (from command above)

## Local Development

```bash
cd app

# Install dependencies
go mod download

# Run tests
go test ./... -v

# Run locally
go run .

# Test endpoints
curl http://localhost:8080/healthz
curl http://localhost:8080/api/message
```

## Cleanup

To avoid ongoing AWS charges, destroy all resources:

```bash
# Delete ArgoCD application first
kubectl delete -f infra/argocd-application.yaml

# Destroy infrastructure
cd infra
terraform destroy
```

## Troubleshooting

### Pods in CrashLoopBackOff

```bash
# Check pod logs
kubectl logs -n fiber-app <pod-name> --previous

# Check pod events
kubectl describe pod -n fiber-app <pod-name>
```

### Load Balancer has no External IP

```bash
# Check service status
kubectl describe svc fiber-app-service -n fiber-app

# Verify security groups allow traffic
```

### ArgoCD not syncing

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Force sync
argocd app sync fiber-app
```

### ECR authentication issues

```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-2.amazonaws.com
```

## Security Features

- **Non-root containers**: Application runs as UID 1001
- **Resource limits**: CPU and memory constraints prevent resource exhaustion
- **Private subnets**: Worker nodes isolated from direct internet access
- **IRSA**: Service accounts use IAM roles (no static credentials)
- **Image scanning**: ECR automatically scans images for vulnerabilities
- **Health probes**: Automatic restart of unhealthy containers

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Submit a pull request

## License

MIT License - See LICENSE file for details
