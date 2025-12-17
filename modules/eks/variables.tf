variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "cluster_version" {
  description = "EKS Cluster Version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the VPC where EKS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Private Subnet IDs for EKS nodes"
  type        = list(string)
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
}