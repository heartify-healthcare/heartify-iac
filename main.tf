module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
  environment  = var.environment
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

module "databases" {
  source = "./modules/databases"

  depends_on = [module.eks] 
}