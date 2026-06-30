# EKS Terraform Module

Production-ready Terraform module for deploying Amazon EKS clusters with comprehensive configurations for enterprise workloads.

## Features

- **EKS Cluster**: Managed Kubernetes cluster with configurable version
- **Managed Node Groups**: General, compute-optimized, memory-optimized, spot, and GPU node groups
- **IRSA (IAM Roles for Service Accounts)**: Pre-configured roles for common controllers
- **Encryption**: KMS encryption for secrets at rest
- **EKS Add-ons**: VPC-CNI, CoreDNS, kube-proxy, EBS CSI driver
- **Security Groups**: Comprehensive network security rules
- **Logging**: CloudWatch control plane logging
- **Karpenter Support**: Optional Karpenter for dynamic node provisioning
- **GPU/EFA Support**: ML/AI workload support

## Usage

### Basic Example

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "my-cluster"
  cluster_version = "1.28"

  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  tags = {
    Environment = "production"
  }
}
```

### Full Example with Node Groups

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "retail-store-prod"
  cluster_version = "1.28"

  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  managed_node_groups = {
    general = {
      instance_types = ["m5.xlarge", "m6i.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      labels = {
        workload = "general"
      }
    }
  }

  enable_compute_node_group = true
  enable_spot_node_group    = true
  enable_karpenter          = false
  enable_cluster_autoscaler = true

  cluster_endpoint_public_access_cidrs = ["10.0.0.0/8"]
  encryption_config = {
    enabled   = true
    resources = ["secrets"]
  }

  admins = [
    "arn:aws:iam::123456789012:role/AdminRole"
  ]

  tags = {
    Environment = "production"
    Project     = "retail-store"
  }
}
```

## Node Groups

### General Node Group (Default)

```hcl
managed_node_groups = {
  general = {
    instance_types = ["m5.large", "m6i.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    min_size       = 2
    max_size       = 10
    desired_size   = 3
    labels = {
      workload = "general"
    }
  }
}
```

### Compute Node Group

```hcl
enable_compute_node_group = true
compute_node_group_config = {
  instance_types = ["c5.large", "c6i.large"]
  min_size       = 0
  max_size       = 5
  desired_size   = 1
}
```

### Memory Node Group

```hcl
enable_memory_node_group = true
memory_node_group_config = {
  instance_types = ["r5.large", "r6i.large"]
  min_size       = 0
  max_size       = 5
  desired_size   = 1
}
```

### Spot Node Group

```hcl
enable_spot_node_group = true
spot_node_group_config = {
  instance_types = ["m5.large", "m6i.large", "c5.large"]
  min_size       = 0
  max_max        = 10
  desired_size   = 2
}
```

### GPU Node Group

```hcl
enable_gpu_node_group = true
gpu_node_group_config = {
  instance_types = ["g5.xlarge", "g4dn.xlarge"]
  min_size       = 0
  max_size       = 3
  desired_size   = 1
}
enable_efa_support = true
```

## IRSA Roles

The module creates the following IRSA roles when enabled:

| Role | Service Account | Namespace |
|------|----------------|-----------|
| VPC CNI | aws-node | kube-system |
| EBS CSI | ebs-csi-controller-sa | kube-system |
| AWS Load Balancer Controller | aws-load-balancer-controller | kube-system |
| Cluster Autoscaler | cluster-autoscaler | kube-system |
| ExternalDNS | external-dns | kube-system |
| External Secrets | external-secrets | external-secrets |
| CloudWatch Agent | cloudwatch-agent | amazon-cloudwatch |
| Karpenter | karpenter | kube-system |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0, < 6.0 |
| kubernetes | >= 2.23.0, < 3.0.0 |
| tls | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0, < 6.0 |

## Remote State

Example for using remote VPC state:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "vpc/production/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Security Best Practices

1. **Encryption at Rest**: Enable KMS encryption for secrets
2. **Private Endpoint**: Use private endpoint for production
3. **CIDR Restrictions**: Restrict API access to known CIDRs
4. **Least Privilege**: Minimal IAM policies for IRSA roles
5. **Pod Security**: Configure pod security groups
6. **Network Policies**: Use Calico or native network policies
7. **Logging**: Enable all control plane log types

## Connecting to the Cluster

After deployment, configure kubectl:

```bash
aws eks update-kubeconfig --name my-cluster --region us-east-1
```

Or use the generated kubeconfig from outputs.

## File Structure

```
modules/eks/
├── main.tf              # EKS cluster and addons
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── node_groups.tf       # Managed node groups
├── iam.tf               # IAM roles and policies
├── kms.tf               # KMS key for encryption
├── security_groups.tf   # Security group rules
├── versions.tf          # Provider version constraints
├── templates/
│   ├── kubeconfig.tpl   # Kubeconfig template
│   └── user_data.tpl    # Node user data script
├── terraform.tfvars     # Example variables
└── README.md            # This file
```

## License

Apache-2.0
