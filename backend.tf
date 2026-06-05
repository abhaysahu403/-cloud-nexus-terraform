# Configure remote state storage in S3
# Uncomment this block after running 'terraform apply' once with local state
# terraform {
#   backend "s3" {
#     bucket         = "cloud-nexus-terraform-state"
#     key            = "prod/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }

# For initial deployment, terraform state will be stored locally
# After first successful deployment, optionally enable S3 remote state by:
# 1. Creating S3 bucket: aws s3 mb s3://cloud-nexus-terraform-state
# 2. Uncommenting the backend block above
# 3. Running: terraform init
