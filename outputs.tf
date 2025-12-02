output "configure_kubectl" {
  description = "Lệnh cấu hình kubectl"
  value       = "aws eks --region ap-southeast-1 update-kubeconfig --name ${module.k8s_cluster.cluster_name}"
}