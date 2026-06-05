resource "aws_db_instance" "mysql" {
  identifier            = "${var.project_name}-db"
  engine                = "mysql"
  engine_version        = "8.0.35"
  instance_class        = var.instance_type
  allocated_storage     = 5
  storage_type          = "gp2"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  parameter_group_name  = "default.mysql8.0"
  skip_final_snapshot   = true
  publicly_accessible   = false
  multi_az              = false
  backup_retention_period = 1
  db_subnet_group_name  = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]
  storage_encrypted     = false

  tags = {
    Name = "${var.project_name}-mysql"
  }
}

# Cloud watch log group for RDS
resource "aws_cloudwatch_log_group" "mysql_error" {
  name              = "/aws/rds/${var.project_name}-mysql-error"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-mysql-error-logs"
  }
}
