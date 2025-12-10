output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

# Lệnh để update kubeconfig nhanh
output "configure_kubectl" {
  description = "Configure kubectl: run this command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "postgres_endpoint" {
  description = "Endpoint của User Database (Postgres)"
  # SỬA TỪ: db_endpoint -> THÀNH: db_instance_endpoint
  value       = module.user_database.postgres_endpoint
}

output "documentdb_endpoint" {
  description = "Endpoint của AI Database (DocumentDB)"
  # SỬA TỪ: db_endpoint -> THÀNH: cluster_endpoint (hoặc endpoint)
  value       = module.ai_database.documentdb_endpoint 
}

output "ecr_repository_urls" {
  description = "URL của các ECR Repositories"
  value       = module.ecr.repository_urls
}

output "lb_controller_role_arn" {
  description = "ARN của IAM Role dùng cho Load Balancer Controller"
  value       = module.lb_role.iam_role_arn
}