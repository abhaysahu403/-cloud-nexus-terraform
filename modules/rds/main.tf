resource "aws_db_instance" "mysql" {
  identifier            = "${var.project_name}-db"
  engine                = "mysql"
  engine_version        = "8.0.35"
  instance_class        = var.instance_type
  allocated_storage     = 20
  storage_type          = "gp2"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  parameter_group_name  = "default.mysql8.0"
  skip_final_snapshot   = true
  publicly_accessible   = false
  db_subnet_group_name  = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]

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
