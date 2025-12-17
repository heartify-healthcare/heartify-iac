variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "heartify"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default     = "heartify-cluster"
}