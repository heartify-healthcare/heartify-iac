# heartify-iac

Infrastructure as Code (IaC) for Heartify project using Terraform. This repository provisions a complete AWS infrastructure including VPC networking and EKS Kubernetes cluster.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Account                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              VPC (Virtual Private Cloud)             │   │
│  │                                                      │   │
│  │  ┌──────────────┐         ┌──────────────┐           │   │
│  │  │   Public     │         │   Private    │           │   │
│  │  │  Subnet 1    │         │  Subnet 1    │           │   │
│  │  │ (AZ: us-*-a) │         │ (AZ: us-*-a) │           │   │
│  │  └──────────────┘         └──────────────┘           │   │
│  │                                                      │   │
│  │  ┌──────────────┐         ┌──────────────┐           │   │
│  │  │   Public     │         │   Private    │           │   │
│  │  │  Subnet 2    │         │  Subnet 2    │           │   │
│  │  │ (AZ: us-*-b) │         │ (AZ: us-*-b) │           │   │
│  │  └──────────────┘         └──────────────┘           │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         EKS Kubernetes Cluster                        │  │
│  │                                                       │  │
│  │  ┌───────────────────────────────────────────────┐    │  │
│  │  │      EKS Control Plane (Managed)              │    │  │
│  │  │  • Kubernetes API Server                      │    │  │
│  │  │  • etcd Database                              │    │  │
│  │  │  • Scheduler & Controllers                    │    │  │
│  │  └───────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌──────────────┐    ┌──────────────┐                 │  │
│  │  │  Worker Node │    │  Worker Node │   ...           │  │
│  │  │   Group 1    │    │   Group 1    │                 │  │
│  │  │ (min: 1,     │    │ (min: 1,     │                 │  │
│  │  │  max: 10)    │    │  max: 10)    │                 │  │
│  │  └──────────────┘    └──────────────┘                 │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │    KMS Encryption Key (for sensitive data)            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
heartify-iac/
├── main.tf              # Root module configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output values
├── provider.tf          # AWS provider configuration
├── terraform.tfstate    # State file (track current infrastructure)
├── README.md            # This file
├── .gitignore           # Git ignore rules
│
└── modules/             # Reusable Terraform modules
    ├── vpc/             # VPC networking module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── eks/             # EKS Kubernetes cluster module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS Account with sufficient permissions
- `kubectl` (for interacting with the EKS cluster)

## Configuration

### Main Components

1. **VPC Module** (`modules/vpc/`)
   - Virtual Private Cloud with public and private subnets
   - Multi-AZ deployment for high availability
   - NAT Gateway for private subnet internet access

2. **EKS Module** (`modules/eks/`)
   - AWS EKS managed Kubernetes cluster
   - Auto-scaling managed node groups
   - IRSA (IAM Roles for Service Accounts) enabled
   - KMS encryption for secrets

3. **KMS Module** (`modules/kms/` - via Terraform modules)
   - Encryption key for EKS cluster secrets

## Getting Started

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply Configuration

```bash
terraform apply
```

### 4. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region $(terraform output -raw aws_region) \
  --name $(terraform output -raw cluster_name)
```

### 5. Verify Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Variables

See [variables.tf](variables.tf) for configurable parameters:

- `cluster_name` - EKS cluster name
- `cluster_version` - Kubernetes version (e.g., "1.28")
- `min_size` - Minimum number of worker nodes
- `max_size` - Maximum number of worker nodes
- `desired_size` - Desired number of worker nodes
- `node_instance_types` - EC2 instance types for worker nodes

## Outputs

See [outputs.tf](outputs.tf) for available outputs:

- `cluster_name` - EKS cluster name
- `cluster_endpoint` - Kubernetes API endpoint
- `aws_region` - AWS region

Access outputs with:

```bash
terraform output
terraform output cluster_name
```

## Security Features

✅ **IAM Integration**
- Cluster creator has admin permissions
- IRSA (IAM Roles for Service Accounts) enabled

✅ **Authentication**
- API-based authentication with ConfigMap fallback
- Public API endpoint for kubectl access

✅ **Encryption**
- KMS key for EKS secrets encryption

✅ **Network**
- VPC isolation with public/private subnets
- Managed NAT Gateways

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**⚠️ Warning:** This will delete all infrastructure including the EKS cluster and data.

## Troubleshooting

### Check Terraform State

```bash
terraform state list
terraform state show <resource>
```

### View Detailed Logs

```bash
export TF_LOG=DEBUG
terraform plan
```

### EKS Cluster Access Issues

```bash
# Verify kubeconfig
kubectl config view

# Check cluster connection
kubectl cluster-info
```

## File References

- [modules/eks/main.tf](modules/eks/main.tf) - EKS configuration
- [modules/vpc/main.tf](modules/vpc/main.tf) - VPC configuration
- [main.tf](main.tf) - Root module
- [variables.tf](variables.tf) - Variable definitions
- [outputs.tf](outputs.tf) - Output values

## Contributing

Please follow Terraform best practices and test changes with `terraform plan` before applying.
