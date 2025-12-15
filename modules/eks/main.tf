module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # allowing public access to the EKS control plane
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  
  eks_managed_node_groups = {
    
    # 1. General Node Group (Backend Java, System)
    general = {
      name           = "general-cpu-ng"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      labels = {
        role = "general"
      }
      
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
    }

    ai_cpu = {
      name           = "ai-cpu-ng"
      instance_types = ["t3.large"] 
      min_size       = 1
      max_size       = 3
      desired_size   = 1

      labels = {
        role = "ai-inference"
      }
      
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
    }

    # 3. GPU Node Group 
    /*
    gpu = {
      name           = "gpu-inference-ng"
      instance_types = ["g4dn.xlarge"]
      ami_type       = "AL2_x86_64_GPU" # AMI riêng cho GPU
      min_size       = 0
      max_size       = 5
      desired_size   = 1

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
    }
    */
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # Đây là driver quan trọng còn thiếu
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.irsa_ebs_csi.iam_role_arn
    }
  }
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

module "irsa_ebs_csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.34"

  role_name             = "heartify-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}