terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# Frontend EC2 Module
module "frontend_ec2" {
  source = "./modules/frontend-ec2"
  
  project_name               = var.project_name
  environment                = var.environment
  instance_type              = var.ec2_instance_type
  subnet_id                  = module.vpc.public_subnet_id
  security_group_id          = module.security_groups.frontend_sg_id
  ssh_key_name               = var.ssh_key_name
  backend_public_ip          = module.backend_ec2.public_ip
  frontend_repo_url          = "https://github.com/abhaysahu403/cloudnexus-frontend.git"
}

# Backend EC2 Module
module "backend_ec2" {
  source = "./modules/backend-ec2"
  
  project_name         = var.project_name
  environment          = var.environment
  instance_type        = var.ec2_instance_type
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = module.security_groups.backend_sg_id
  ssh_key_name         = var.ssh_key_name
  rds_endpoint         = module.rds.endpoint
  s3_bucket_name       = module.s3.bucket_name
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  backend_repo_url     = "https://github.com/abhaysahu403/cloudnexus-backend.git"
}

# RDS Module
module "rds" {
  source = "./modules/rds"
  
  project_name                 = var.project_name
  environment                  = var.environment
  instance_type                = var.rds_instance_type
  db_name                      = var.db_name
  db_username                  = var.db_username
  db_password                  = var.db_password
  db_subnet_group_name         = module.vpc.db_subnet_group_name
  rds_security_group_id        = module.security_groups.rds_sg_id
  database_repo_url            = "https://github.com/abhaysahu403/cloudnexus-database.git"
}

# S3 Module
module "s3" {
  source = "./modules/s3"
  
  project_name  = var.project_name
  environment   = var.environment
}
