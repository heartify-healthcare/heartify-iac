resource "random_password" "postgres_password" {
  length  = 16
  special = false
}

resource "random_password" "mongo_password" {
  length           = 16
  special          = false
  override_special = "!@#%&" # Mongo kén ký tự đặc biệt hơn
}