# 1. EKS Control Plane
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true 
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# 2. General Node Group (CPU - For API, Reporting, System Pods)
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "general-cpu-ng"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t3.medium"] # Cost-effective for general purpose
  ami_type       = "AL2_x86_64"  # Amazon Linux 2 Standard

  # Labels to help with scheduling if needed
  labels = {
    "role" = "general"
  }

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}

# 3. AI/GPU Node Group (For Denoising & Classification Models)
resource "aws_eks_node_group" "gpu" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "gpu-inference-ng"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 1 # Start with 1 to save cost
    max_size     = 5 # Auto-scale up when load increases
    min_size     = 0 # Can scale to 0 if using Cluster Autoscaler effectively
  }

  # GPU Instance Selection
  # g4dn.xlarge: 4 vCPUs, 16GB RAM, 1 NVIDIA T4 GPU (16GB VRAM)
  # Excellent for inference (Wav2Vec 2.0 and U-Net)
  instance_types = ["g4dn.xlarge"] 
  
  # IMPORTANT: Use GPU Optimized AMI
  ami_type       = "AL2_x86_64_GPU" 

  # Taints: Prevents regular pods from scheduling here
  taint {
    key    = "accelerator"
    value  = "nvidia-tesla-t4"
    effect = "NO_SCHEDULE"
  }

  labels = {
    "role"        = "ai-inference"
    "accelerator" = "nvidia-tesla-t4"
  }

  disk_size = 50 # Larger disk for AI models and docker images

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}