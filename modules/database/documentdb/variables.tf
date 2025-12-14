variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "eks_node_sg_id" {}
variable "identifier" {}
variable "db_name" {}
variable "db_username" { default = "postgres" }