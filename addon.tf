# addons.tf

# install NVIDIA Device Plugin for Kubernetes (Compulsory for GPU Node)
# resource "helm_release" "nvidia_device_plugin" {
#   name       = "nvidia-device-plugin"
#   repository = "https://nvidia.github.io/k8s-device-plugin"
#   chart      = "nvidia-device-plugin"
#   namespace  = "kube-system"
#   version    = "0.14.0"

#   # Đảm bảo EKS xong rồi mới cài cái này
#   depends_on = [module.eks]
# }

# Install AWS Load Balancer Controller (Compulsory for ALB Ingress)
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.lb_role.iam_role_arn
  }

  depends_on = [module.eks, module.lb_role]
}