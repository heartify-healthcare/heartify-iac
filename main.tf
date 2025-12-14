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
    "heartify/ai-service",
    "heartify/user-service",
    "heartify/api-gateway",
    "heartify/classify-model",
    "heartify/config-server",
    "heartify/denoised-model",
    "heartify/eureka-server",
  ]
}

module "eks" {
  source = "./modules/eks" 

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  environment     = var.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

module "user_database" {
  source = "./modules/database/postgres"

  identifier      = "user-service-db"
  db_name         = "userdb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  eks_node_sg_id  = module.eks.node_security_group_id 
}


module "ai_database" {
  source = "./modules/database/documentdb"

  identifier      = "ai-service-db"
  db_name        = "aidb"
  db_username     = "aiadmin"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  eks_node_sg_id  = module.eks.node_security_group_id 
}