# Cloud Nexus HR - Terraform Infrastructure

AWS Infrastructure as Code for 3-tier HR Management Platform

## Architecture

- Frontend EC2 (React + Docker)
- Backend EC2 (Node.js + Docker)
- RDS MySQL (Private Subnet)
- S3 Bucket (Uploads)

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

- frontend_public_ip
- backend_public_ip
- rds_endpoint
- s3_bucket_name
