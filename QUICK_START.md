# Quick Start - Cloud Nexus HR Terraform Deployment

## 5-Minute Setup

### 1. Create SSH Key (if not exists)
```bash
aws ec2 create-key-pair --key-name cloud-nexus-key --region us-east-1 \
  --query 'KeyMaterial' --output text > ~/.ssh/cloud-nexus-key.pem
chmod 600 ~/.ssh/cloud-nexus-key.pem
```

### 2. Clone and Configure
```bash
git clone https://github.com/abhaysahu403/cloud-nexus-terraform.git
cd cloud-nexus-terraform

# Edit terraform.tfvars - ensure ssh_key_name = "cloud-nexus-key"
# Change db_password to something strong
```

### 3. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 4. Get Outputs
```bash
echo "Frontend: http://$(terraform output -raw frontend_public_ip):3000"
echo "Backend: http://$(terraform output -raw backend_public_ip):5000"
echo "Database: $(terraform output -raw rds_endpoint)"
echo "S3 Bucket: $(terraform output -raw s3_bucket_name)"
```

### 5. Verify
```bash
# Test Frontend
curl http://$(terraform output -raw frontend_public_ip):3000

# Test Backend
curl http://$(terraform output -raw backend_public_ip):5000/api/employees
```

## GitHub Actions Setup (5 minutes)

### Frontend Repo
1. Go to repo settings → Secrets and variables → Actions
2. Add secrets:
   - `FRONTEND_EC2_IP` = output from step 4
   - `BACKEND_API_URL` = http://<backend-ip>:5000/api
   - `EC2_SSH_KEY` = (content of ~/.ssh/cloud-nexus-key.pem)

### Backend Repo
1. Go to repo settings → Secrets and variables → Actions
2. Add secrets (use values from outputs + terraform.tfvars):
   - `BACKEND_EC2_IP`
   - `EC2_SSH_KEY`
   - `DB_HOST` = RDS endpoint
   - `DB_USER` = admin
   - `DB_PASSWORD` = (from tfvars)
   - `S3_BUCKET_NAME`
   - `JWT_SECRET` = (generate random)
   - `CORS_ORIGIN` = http://<frontend-ip>:3000

### Terraform Repo
1. Go to repo settings → Secrets and variables → Actions
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

## Testing (Push to Deploy)

```bash
# Frontend: Make a change, push to main
git -C <frontend> commit -am "Update UI" && git -C <frontend> push

# Backend: Make a change, push to main
git -C <backend> commit -am "Fix API" && git -C <backend> push

# Both will auto-deploy via GitHub Actions
```

## Common Commands

```bash
# View all outputs
terraform output

# SSH to Frontend
ssh -i ~/.ssh/cloud-nexus-key.pem ec2-user@$(terraform output -raw frontend_public_ip)

# SSH to Backend
ssh -i ~/.ssh/cloud-nexus-key.pem ec2-user@$(terraform output -raw backend_public_ip)

# View EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=cloud-nexus-hr-*" --region us-east-1

# View RDS
aws rds describe-db-instances --db-instance-identifier cloud-nexus-hr-db --region us-east-1

# View S3
aws s3 ls s3://$(terraform output -raw s3_bucket_name)

# Destroy all (cleanup)
terraform destroy
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `permission denied` SSH | Check key permissions: `chmod 600 ~/.ssh/cloud-nexus-key.pem` |
| Container not running | SSH to EC2, run `docker logs <container-name>` |
| Can't reach RDS | Check security group allows 3306 from backend SG |
| S3 upload fails | Ensure backend has AWS SDK: `npm install @aws-sdk/client-s3` |
| GitHub Actions fails | Check secrets are set correctly in repo settings |
| Terraform destroy hangs | Force: `terraform destroy -auto-approve` |

## Estimated Costs

**First 12 months (Free Tier):**
- t3.micro EC2: Free (750 hrs/month included)
- db.t3.micro RDS: Free (750 hrs/month included)
- S3: Free (5GB included)
- **Total: $0/month**

**After Free Tier:**
- 2x EC2: ~$15.20/month
- 1x RDS: ~$8.47/month
- S3: ~$0.12/month
- **Total: ~$24/month**

## Architecture

```
┌─────────────────────────────────────────────┐
│           Internet Gateway                  │
└─────────────────────────────────────────────┘
         ↓              ↓
    Port 3000      Port 5000
        ↓              ↓
┌──────────────┐ ┌──────────────┐
│  Frontend    │ │   Backend    │
│  EC2 Public  │ │  EC2 Public  │
│ 10.0.1.0/24  │ │ 10.0.1.0/24  │
└──────────────┘ └──────────────┘
        ↓              ↓
        └──────────┬───┘
                   ↓ Port 3306
            ┌──────────────┐
            │  RDS MySQL   │
            │ 10.0.2.0/24  │
            │   Private    │
            └──────────────┘
        
┌──────────────────────────┐
│      S3 Bucket           │
│  Uploads, Resumes, Docs  │
└──────────────────────────┘
```

## Next Steps

1. ✅ Deploy infrastructure
2. ✅ Verify all services running
3. ✅ Set up GitHub Actions
4. ✅ Test auto-deployment
5. Optional: Enable remote state in S3
6. Optional: Set up monitoring/alerts
7. Optional: Configure backups

See `DEPLOYMENT_GUIDE.md` for detailed instructions and `CHECKLIST.md` for verification steps.
