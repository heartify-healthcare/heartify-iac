# modules/database/postgres/main.tf

# 1. Security Group: Chỉ cho phép EKS Node truy cập
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for ${var.identifier}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id] # Chỉ nhận từ EKS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
}

# 3. Tạo Random Password & Secret
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@" # Tránh các ký tự gây lỗi URL
}

resource "aws_secretsmanager_secret" "this" {
  name = "/prod/${var.identifier}/credentials"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.password.result
    host     = aws_db_instance.this.address
    port     = 5432
    dbname   = var.db_name
  })
}

# 4. RDS Instance
resource "aws_db_instance" "this" {
  identifier             = var.identifier
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.password.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  skip_final_snapshot    = true # Set false nếu là production thật
  deletion_protection    = true
}