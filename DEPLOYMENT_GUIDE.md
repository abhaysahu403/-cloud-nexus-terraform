# Cloud Nexus HR Platform - Terraform Deployment Guide

## Prerequisites
- AWS Account configured with credentials
- Terraform installed (v1.5+)
- AWS CLI configured
- EC2 Key Pair created in us-east-1
- GitHub SSH keys configured for private repos

## Quick Start

### Step 1: Create EC2 Key Pair
```bash
aws ec2 create-key-pair --key-name cloud-nexus-key --region us-east-1 --query 'KeyMaterial' --output text > ~/.ssh/cloud-nexus-key.pem
chmod 600 ~/.ssh/cloud-nexus-key.pem
```

### Step 2: Verify terraform.tfvars
Edit `terraform.tfvars` and ensure values are correct:
```hcl
ssh_key_name       = "cloud-nexus-key"          # Must match your EC2 key pair
db_password        = "CloudNexus@2024"          # Change to strong password
```

### Step 3: Initialize Terraform
```bash
cd repos/terraform
terraform init
terraform plan
```

### Step 4: Review and Apply
```bash
terraform apply
```

After successful apply, note the outputs:
- frontend_public_ip: http://<IP>:3000
- backend_public_ip: http://<IP>:5000
- rds_endpoint: MySQL endpoint
- s3_bucket_name: S3 bucket for uploads

## Architecture

```
Internet Gateway (IGW)
│
├─ Frontend EC2 (t3.micro) - Public Subnet
│  ├─ Port 22: SSH (0.0.0.0/0)
│  ├─ Port 3000: React App (0.0.0.0/0)
│  └─ VPC: 10.0.1.0/24
│
├─ Backend EC2 (t3.micro) - Public Subnet
│  ├─ Port 22: SSH (0.0.0.0/0)
│  ├─ Port 5000: Node.js API (0.0.0.0/0)
│  └─ VPC: 10.0.1.0/24
│
├─ RDS MySQL (db.t3.micro) - Private Subnet
│  ├─ Port 3306: MySQL (Backend SG only)
│  ├─ Database: cloudnexushr
│  └─ VPC: 10.0.2.0/24
│
└─ S3 Bucket
   └─ Uploads, resumes, documents
```

## Deployment Verification

### 1. SSH to Frontend EC2
```bash
SSH_KEY=~/.ssh/cloud-nexus-key.pem
FRONTEND_IP=$(terraform output frontend_public_ip | tr -d '"')
ssh -i $SSH_KEY ec2-user@$FRONTEND_IP
docker ps  # Should show cloud-nexus-frontend
```

### 2. SSH to Backend EC2
```bash
BACKEND_IP=$(terraform output backend_public_ip | tr -d '"')
ssh -i $SSH_KEY ec2-user@$BACKEND_IP
docker ps  # Should show cloud-nexus-backend
```

### 3. Test Frontend
```bash
curl http://$FRONTEND_IP:3000
```

### 4. Test Backend API
```bash
curl http://$BACKEND_IP:5000/api/employees
```

### 5. Verify Database Connection
```bash
ssh -i $SSH_KEY ec2-user@$BACKEND_IP
RDS_ENDPOINT=$(terraform output rds_endpoint | tr -d '"')
mysql -h $RDS_ENDPOINT -u admin -p -e "USE cloudnexushr; SHOW TABLES;"
```

### 6. Test S3 Upload
```bash
S3_BUCKET=$(terraform output s3_bucket_name | tr -d '"')
aws s3 ls s3://$S3_BUCKET
```

## GitHub Actions Setup

### 1. Add GitHub Secrets (for Frontend repo)
```
FRONTEND_EC2_IP=<public-ip-from-terraform-output>
BACKEND_API_URL=http://<backend-public-ip>:5000/api
EC2_SSH_KEY=<content-of-cloud-nexus-key.pem>
```

### 2. Add GitHub Secrets (for Backend repo)
```
BACKEND_EC2_IP=<public-ip-from-terraform-output>
EC2_SSH_KEY=<content-of-cloud-nexus-key.pem>
DB_HOST=<rds-endpoint-from-terraform-output>
DB_USER=admin
DB_PASSWORD=<from-terraform.tfvars>
S3_BUCKET_NAME=<from-terraform-output>
JWT_SECRET=<generate-secure-key>
CORS_ORIGIN=http://<frontend-public-ip>:3000
```

### 3. Add GitHub Secrets (for Terraform repo)
```
AWS_ACCESS_KEY_ID=<your-aws-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret>
```

## Cost Estimation

**Free Tier (first 12 months):**
- EC2: 2x t3.micro instances (750 hrs/month included)
- RDS: db.t3.micro MySQL (750 hrs/month included)
- S3: 5GB free tier
- Total: **$0/month** (if within free tier limits)

**After Free Tier:**
- EC2: ~$0.0104/hour × 730 hours = ~$7.60/month per instance
- RDS: ~$0.0116/hour × 730 hours = ~$8.47/month
- S3: ~$0.023/GB × 5GB = ~$0.12/month
- Total: ~**$23/month**

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

Verify deletion:
```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=cloud-nexus-hr-*" --region us-east-1
```

## Troubleshooting

### EC2 User Data Script Failed
```bash
# SSH to EC2 and check logs
ssh -i ~/.ssh/cloud-nexus-key.pem ec2-user@<IP>
sudo tail -100 /var/log/cloud-init-output.log
```

### Docker Container Not Running
```bash
docker logs cloud-nexus-frontend
docker logs cloud-nexus-backend
```

### Database Connection Failed
```bash
# From Backend EC2
mysql -h <RDS_ENDPOINT> -u admin -p
# If fails, check:
# 1. RDS Security Group allows port 3306 from Backend SG
# 2. Backend .env has correct DB_HOST and DB_PASSWORD
```

### S3 Upload Fails
```bash
# Check S3 bucket exists and CORS is enabled
aws s3api get-bucket-cors --bucket <BUCKET_NAME> --region us-east-1
```

## Security Notes

1. **SSH Access:** Opened to 0.0.0.0/0 for development. Restrict to your IP in production.
2. **Database Password:** Change default password in terraform.tfvars before deployment.
3. **JWT Secret:** Set secure value via GitHub Actions secrets.
4. **S3 Bucket:** Made public-read for testing. Use CloudFront in production.

## Monitoring

### CloudWatch Logs
```bash
# View RDS error logs
aws logs tail /aws/rds/cloud-nexus-hr-db-error --follow
```

### EC2 Monitoring
```bash
aws ec2 monitor-instances --instance-ids <INSTANCE_ID> --region us-east-1
```

## Next Steps

1. Configure GitHub Actions secrets
2. Test manual deployment
3. Configure CI/CD for auto-deployment
4. Set up monitoring and alerts
5. Configure backup and disaster recovery
