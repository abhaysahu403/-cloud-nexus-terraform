data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.ssh_key_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    rds_endpoint   = var.rds_endpoint
    s3_bucket_name = var.s3_bucket_name
    db_name        = var.db_name
    db_username    = var.db_username
    db_password    = var.db_password
    repo_url       = var.backend_repo_url
  }))

  tags = {
    Name = "${var.project_name}-backend"
  }

  depends_on = []
}

resource "aws_eip" "backend" {
  instance = aws_instance.backend.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-backend-eip"
  }
}
