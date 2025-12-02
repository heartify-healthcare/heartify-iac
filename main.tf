# 1. Gọi Module VPC
module "networking" {
  source = "./modules/vpc"

  vpc_name   = "my-k8s-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["ap-southeast-1a", "ap-southeast-1b"] # Chọn AZ phù hợp
}

# 2. Gọi Module EKS
module "k8s_cluster" {
  source = "./modules/eks"

  cluster_name    = "my-app-cluster"
  cluster_version = "1.28" # Chọn version K8s mới nhất
  
  # Lấy output từ module networking truyền vào module eks
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnets 

  # Cấu hình node
  node_instance_types = ["t3.micro"] # Đủ dùng cho test. AI/DL cần g4dn.xlarge
  min_size     = 1
  max_size     = 3
  desired_size = 2
}