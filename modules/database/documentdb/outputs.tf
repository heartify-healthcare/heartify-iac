output "documentdb_endpoint" {
  description = "The cluster endpoint"
  value       = aws_docdb_cluster.this.endpoint
}