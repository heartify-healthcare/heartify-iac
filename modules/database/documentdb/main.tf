# modules/database/documentdb/main.tf

# 1. Security Group (Port 27017)
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id] # Chỉ nhận từ EKS
  }
}



# 2. Subnet Group
resource "aws_docdb_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
}

# 3. Password & Secret
resource "random_password" "password" {
  length           = 16
  special          = false # DocDB kén ký tự đặc biệt hơn
}

resource "aws_secretsmanager_secret" "this" {
  name = "/prod/${var.identifier}/credentials"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.password.result
    host     = aws_docdb_cluster.this.endpoint
    port     = 27017
  })
}

# 4. DocumentDB Cluster
resource "aws_docdb_cluster" "this" {
  cluster_identifier      = var.identifier
  engine                  = "docdb"
  master_username         = var.db_username
  master_password         = random_password.password.result
  db_subnet_group_name    = aws_docdb_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]
  skip_final_snapshot     = true
  storage_encrypted       = true
  deletion_protection     = false
}

# 5. Cluster Instances (Node mạng thực tế)
resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1 # Tăng lên 2-3 cho High Availability
  identifier         = "${var.identifier}-inst-${count.index}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = "db.t3.medium"
}