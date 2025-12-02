module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2" # Nên pin version cụ thể

  name = var.vpc_name
  cidr = var.cidr_block

  azs             = var.azs
  private_subnets = [for k, v in var.azs : cidrsubnet(var.cidr_block, 4, k)]
  public_subnets  = [for k, v in var.azs : cidrsubnet(var.cidr_block, 4, k + 4)]

  enable_nat_gateway = true
  single_nat_gateway = true # Tiết kiệm chi phí (Production nên để false để HA)
  enable_vpn_gateway = false

  # Tags bắt buộc cho EKS Auto-discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}