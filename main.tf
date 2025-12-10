data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0" # Stable version

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # CIDR split into subnets.
  # Private subnets: for node groups and databases (no public IPs).
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  # Public subnets for Load Balancers and NAT Gateways.
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # NAT Gateways: allow private nodes to access the internet.
  enable_nat_gateway = true
  single_nat_gateway = true # Single NAT to reduce cost (dev/staging). Use false for prod.
  enable_vpn_gateway = false

  # DNS required for EKS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required by EKS so AWS places load balancers correctly.
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Terraform   = "true"
    Environment = var.environment
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "ecr" {
  source           = "./modules/ecr"
  repository_names = [
    "heartify-denoising",
    "heartify-classification",
    "heartify-reporting",
    "heartify-api"
  ]
}

module "eks" {
  # CHANGE: use official module instead of local ./modules/eks
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29" # Stable EKS version

  # Network configuration
  vpc_id     = module.vpc.vpc_id
  # Use private_subnets output from VPC module (standard output name: private_subnets)
  subnet_ids = module.vpc.private_subnets 

  # Allow public access to the cluster endpoint for kubectl from personal machines
  cluster_endpoint_public_access = true

  # --- Node groups ---
  eks_managed_node_groups = {
    
    # General node group for API, logging, and system pods
    general = {
      name           = "general-cpu-ng"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Disk configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }
      
      labels = {
        role = "general"
      }
    }

    # GPU node group for AI models (inference)
    gpu = {
      name = "gpu-inference-ng"
      
      # g4dn.xlarge (NVIDIA T4) - good cost/performance for inference
      instance_types = ["g4dn.xlarge"]
      
      # IMPORTANT: choose the correct AMI type for GPU
      ami_type = "AL2_x86_64_GPU" 

      min_size     = 0 # scale-to-zero to save cost when unused
      max_size     = 5
      desired_size = 1

      # Taints to prevent non-AI pods from scheduling here
      taints = {
        dedicated = {
          key    = "accelerator"
          value  = "nvidia-tesla-t4"
          effect = "NO_SCHEDULE"
        }
      }

      labels = {
        role        = "ai-inference"
        accelerator = "nvidia-tesla-t4"
      }

      # Larger disk for heavy AI Docker images (PyTorch, TensorFlow)
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}

module "user_database" {
  source = "./modules/database/postgres"

  identifier      = "user-service-db"
  db_name         = "userdb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  eks_node_sg_id  = module.eks.node_security_group_id # ID của EKS Node Group Security Group
}

# ---------------------------------------------------------
# 2. Gọi Module AI Database (DocumentDB / MongoDB)
# ---------------------------------------------------------
module "ai_database" {
  source = "./modules/database/documentdb"

  identifier      = "ai-service-db"
  db_name        = "aidb"
  db_username     = "aiadmin"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  eks_node_sg_id  = module.eks.node_security_group_id # Dùng chung SG của EKS Node để cho phép truy cập
}