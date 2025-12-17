output "vpc_id" {
  description = "ID of the VPC"
  value = module.vpc.vpc_id
}

output "private_subnets" {
  description = "private subnet CIDR blocks"
  value = module.vpc.private_subnets
}

output "public_subnet" {
  description = "public subnet CIDR blocks"
  value = module.vpc.public_subnets
}