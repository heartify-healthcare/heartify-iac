module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # --- FIX LỖI JOIN NULL & UNREACHABLE ---
  # Thay vì dùng create_delay_dependencies (gây lỗi khi destroy/plan),
  # ta dùng depends_on native của Terraform.
  depends_on = [module.eks] 

  # 1. Cài đặt AWS Load Balancer Controller
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      {
        name  = "podDisruptionBudget.maxUnavailable"
        value = 1
      },
      {
        name  = "enableServiceMutatorWebhook"
        value = "false"
      }
    ]
  }

  # 2. Cài đặt Monitoring (Prometheus + Grafana)
  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    name          = "kube-prometheus-stack"
    chart_version = "56.6.0"
    repository    = "https://prometheus-community.github.io/helm-charts"
    namespace     = "monitoring"
    create_namespace = true
    
    values = [jsonencode({
      grafana = {
        adminPassword = "admin"
        service = {
          type = "ClusterIP"
        }
      }
      prometheus = {
        prometheusSpec = {
          retention = "5d"
          serviceMonitorSelectorNilUsesHelmValues = false
          serviceMonitorSelector = {}
          serviceMonitorNamespaceSelector = {}
        }
      }
    })]
  }
  
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}