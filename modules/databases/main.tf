# modules/databases/main.tf

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

# --- POSTGRESQL ---
resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.1.12" # Version này dùng image 16.1.0-debian-11-r22 (Đã test ổn định)

  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false
  timeout          = 600
  depends_on       = [kubernetes_namespace.this]

  set {
    name  = "architecture"
    value = "standalone"
  }

  # --- QUAN TRỌNG: KHÔNG OVERRIDE IMAGE TAG ---
  # Xóa toàn bộ đoạn set image.tag
  # Để Helm tự lấy image mặc định đi kèm với Chart
  
  # Cấu hình Database
  set {
    name  = "auth.database"
    value = "heartify_user_db"
  }
  set {
    name  = "auth.username"
    value = "heartify"
  }
  set {
    name  = "auth.password"
    value = random_password.postgres_password.result
  }

  # Cấu hình Ổ cứng
  set {
    name  = "primary.persistence.enabled"
    value = "true"
  }
  set {
    name  = "primary.persistence.size"
    value = "8Gi"
  }
  set {
    name  = "global.storageClass"
    value = "gp2"
  }
}

# --- MONGODB ---
resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "mongodb"
  version    = "18.1.10" # Version này dùng image 7.0.2 ổn định

  namespace        = kubernetes_namespace.this.metadata[0].name
  create_namespace = false
  timeout          = 600
  depends_on       = [kubernetes_namespace.this]

  set {
    name  = "architecture"
    value = "standalone"
  }

  # --- QUAN TRỌNG: KHÔNG OVERRIDE IMAGE TAG ---

  # Cấu hình Database
  set {
    name  = "auth.rootPassword"
    value = random_password.mongo_password.result
  }
  set {
    name  = "auth.usernames[0]"
    value = "heartify"
  }
  set {
    name  = "auth.passwords[0]"
    value = random_password.mongo_password.result
  }
  set {
    name  = "auth.databases[0]"
    value = "heartify_ai_db"
  }

  # Cấu hình Ổ cứng
  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.size"
    value = "8Gi"
  }
  set {
    name  = "global.storageClass"
    value = "gp2"
  }
}

resource "kubernetes_secret" "heartify_secrets" {
  metadata {
    name      = "heartify-secrets"
    namespace = var.namespace
  }
  data = {
    DB_PASSWORD    = random_password.postgres_password.result
    DOCDB_PASSWORD = random_password.mongo_password.result
  }
  depends_on = [helm_release.postgresql, helm_release.mongodb]
}