module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # Nâng cấp lên version 20

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cho phép public access (để chạy kubectl từ máy local)
  cluster_endpoint_public_access = true

  # --- CẤU HÌNH QUYỀN TRUY CẬP (Thay đổi lớn ở v20) ---
  # Cho phép người tạo cluster (bạn/IAM user chạy terraform) có quyền Admin cao nhất
  enable_cluster_creator_admin_permissions = true
  
  # Chế độ xác thực: Vừa dùng API mới, vừa hỗ trợ ConfigMap cũ (an toàn nhất)
  authentication_mode = "API_AND_CONFIG_MAP"

  # --- CẤU HÌNH NODE GROUP ---
  eks_managed_node_groups = {
    general = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
    }
  }

  # Tự động gán quyền IAM cho Service Accounts (IRSA)
  enable_irsa = true
}