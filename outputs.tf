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
  description = "User Database Endpoint (PostgreSQL)"
  value       = module.user_database.postgres_endpoint
}

output "documentdb_endpoint" {
  description = "AI Database Endpoint (DocumentDB)"
  value       = module.ai_database.documentdb_endpoint 
}

output "ecr_repository_urls" {
  description = "ECR Repository URLs"
  value       = module.ecr.repository_urls
}

output "lb_controller_role_arn" {
  description = "IAM Role ARN for LB Controller"
  value       = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
}

