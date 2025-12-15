output "postgres_internal_url" {
  value = "jdbc:postgresql://postgresql.heartify.svc.cluster.local:5432/heartify_user_db"
}

output "mongo_internal_url" {
  value = "mongodb://heartify:${random_password.mongo_password.result}@mongodb.heartify.svc.cluster.local:27017/heartify_ai_db?authSource=heartify_ai_db"
  sensitive = true
}