# Cloud Nexus HR Terraform Deployment Checklist

## Pre-Deployment

- [ ] AWS Account configured with credentials
- [ ] `aws configure` completed successfully
- [ ] Terraform installed (v1.5+)
  ```bash
  terraform --version
  ```
- [ ] SSH key pair created in us-east-1
  ```bash
  aws ec2 create-key-pair --key-name cloud-nexus-key --region us-east-1
  ```
- [ ] SSH key saved securely
  ```bash
  chmod 600 ~/.ssh/cloud-nexus-key.pem
  ```

## Configuration

- [ ] `terraform.tfvars` created with correct values
- [ ] SSH key name matches AWS key pair name
- [ ] Database password set to secure value
- [ ] AWS region set to us-east-1
- [ ] All required variables validated

## Terraform Validation

```bash
terraform init
terraform validate
terraform plan
```

- [ ] `terraform init` completes without errors
- [ ] `terraform validate` shows no errors
- [ ] `terraform plan` shows all resources will be created
- [ ] Plan includes:
  - 1x VPC (10.0.0.0/16)
  - 1x Internet Gateway
  - 2x Subnets (1 public, 1 private)
  - 1x DB Subnet Group
  - 2x Route Tables
  - 3x Security Groups
  - 2x EC2 instances (frontend + backend)
  - 1x RDS MySQL instance
  - 1x S3 bucket
  - 4x Elastic IPs

## Deployment

```bash
terraform apply
```

- [ ] `terraform apply` completes successfully
- [ ] All 16 resources created
- [ ] No errors in output
- [ ] Take note of outputs:
  - frontend_public_ip
  - backend_public_ip
  - rds_endpoint
  - s3_bucket_name

## Post-Deployment Verification

### SSH Connectivity
```bash
FRONTEND_IP=$(terraform output -raw frontend_public_ip)
ssh -i ~/.ssh/cloud-nexus-key.pem ec2-user@$FRONTEND_IP
```

- [ ] Can SSH to frontend EC2
- [ ] Can SSH to backend EC2
- [ ] EC2 instances running
- [ ] Docker daemon running

### Container Verification
```bash
# SSH to Frontend
docker ps
docker logs cloud-nexus-frontend

# SSH to Backend
docker ps
docker logs cloud-nexus-backend
```

- [ ] Frontend container running
- [ ] Backend container running
- [ ] No errors in container logs
- [ ] Both containers have `--restart always`

### Application Access

```bash
FRONTEND_IP=$(terraform output -raw frontend_public_ip)
BACKEND_IP=$(terraform output -raw backend_public_ip)

curl http://$FRONTEND_IP:3000
curl http://$BACKEND_IP:5000/api/employees
```

- [ ] Frontend accessible at http://<IP>:3000
- [ ] Frontend loads React application
- [ ] Backend API responds at http://<IP>:5000
- [ ] Backend returns employee list (JSON)

### Database Connectivity

```bash
ssh -i ~/.ssh/cloud-nexus-key.pem ec2-user@$BACKEND_IP
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
mysql -h $RDS_ENDPOINT -u admin -p -e "USE cloudnexushr; SHOW TABLES;"
```

- [ ] Can connect to RDS from Backend EC2
- [ ] Database `cloudnexushr` exists
- [ ] All 8 tables exist
- [ ] Sample data loaded

### S3 Bucket Verification

```bash
S3_BUCKET=$(terraform output -raw s3_bucket_name)
aws s3 ls s3://$S3_BUCKET
aws s3api get-bucket-cors --bucket $S3_BUCKET
```

- [ ] S3 bucket exists
- [ ] Bucket is accessible
- [ ] CORS configuration present
- [ ] Versioning enabled

### Security Group Verification

```bash
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=cloud-nexus-hr-*" --region us-east-1
```

- [ ] Frontend SG allows port 22, 3000
- [ ] Backend SG allows port 22, 5000
- [ ] RDS SG allows port 3306 from backend only
- [ ] All egress rules allow 0.0.0.0/0

### Network Connectivity

```bash
# From Backend EC2
ping 8.8.8.8  # Internet
curl http://169.254.169.254/latest/meta-data/  # AWS metadata

# From Backend to Frontend
curl http://$FRONTEND_IP:3000
```

- [ ] EC2 instances have internet access
- [ ] Instances can reach AWS metadata service
- [ ] Backend can reach Frontend via internal VPC

## GitHub Actions Setup

### Frontend Repo Secrets
Add these secrets to frontend repository:
```
FRONTEND_EC2_IP = <terraform output frontend_public_ip>
BACKEND_API_URL = http://<terraform output backend_public_ip>:5000/api
EC2_SSH_KEY = <content of ~/.ssh/cloud-nexus-key.pem>
```

- [ ] FRONTEND_EC2_IP set
- [ ] BACKEND_API_URL set
- [ ] EC2_SSH_KEY set

### Backend Repo Secrets
Add these secrets to backend repository:
```
BACKEND_EC2_IP = <terraform output backend_public_ip>
EC2_SSH_KEY = <content of ~/.ssh/cloud-nexus-key.pem>
DB_HOST = <terraform output rds_endpoint>
DB_USER = admin
DB_PASSWORD = <from terraform.tfvars>
S3_BUCKET_NAME = <terraform output s3_bucket_name>
JWT_SECRET = <strong random key>
CORS_ORIGIN = http://<terraform output frontend_public_ip>:3000
```

- [ ] BACKEND_EC2_IP set
- [ ] EC2_SSH_KEY set
- [ ] DB_HOST set
- [ ] DB_USER set
- [ ] DB_PASSWORD set
- [ ] S3_BUCKET_NAME set
- [ ] JWT_SECRET set
- [ ] CORS_ORIGIN set

### Terraform Repo Secrets
Add these secrets to terraform repository:
```
AWS_ACCESS_KEY_ID = <your AWS access key>
AWS_SECRET_ACCESS_KEY = <your AWS secret key>
```

- [ ] AWS_ACCESS_KEY_ID set
- [ ] AWS_SECRET_ACCESS_KEY set

## Testing Deployment Workflow

### Frontend Deployment
```bash
# Push change to frontend repo main branch
git -C <frontend-repo> push origin main
# Watch GitHub Actions workflow complete
```

- [ ] GitHub Actions workflow triggered
- [ ] SSH connection successful
- [ ] Docker image rebuilt
- [ ] Container restarted
- [ ] Frontend still accessible

### Backend Deployment
```bash
# Push change to backend repo main branch
git -C <backend-repo> push origin main
# Watch GitHub Actions workflow complete
```

- [ ] GitHub Actions workflow triggered
- [ ] SSH connection successful
- [ ] Docker image rebuilt
- [ ] Container restarted
- [ ] Backend API still responds

## Cost Verification

```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region us-east-1
```

- [ ] Monitor AWS Billing Dashboard
- [ ] Verify estimated monthly cost
- [ ] Confirm within budget

## Cleanup (When Done)

```bash
terraform destroy
```

- [ ] All resources deleted
- [ ] Elastic IPs released
- [ ] VPC cleaned up
- [ ] No lingering resources

## Troubleshooting Log

Document any issues encountered:

| Issue | Resolution | Resolved |
|-------|-----------|----------|
| | | |
| | | |

## Sign-Off

- [ ] All checklist items completed
- [ ] Application fully functional
- [ ] All tests passed
- [ ] Ready for production

**Date:** _______________
**Verified By:** _______________
