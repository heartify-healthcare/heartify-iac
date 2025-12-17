output "repository_urls" {
  description = "Map of repository names to their URLs"
  # Returns a map like: { "heartify-api" = "012345678901.dkr.ecr.region.amazonaws.com/heartify-api", ... }
  value = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = { for k, v in aws_ecr_repository.repos : k => v.arn }
}