#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
yum install docker -y
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install git and mysql client
yum install git mysql-community-client -y

# Create app directory
mkdir -p /opt/cloud-nexus-backend
cd /opt/cloud-nexus-backend

# Clone repository
git clone ${repo_url} .

# Create .env file
cat > .env << EOF
DB_HOST=${rds_endpoint}
DB_PORT=3306
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
AWS_REGION=us-east-1
S3_BUCKET_NAME=${s3_bucket_name}
NODE_ENV=production
PORT=5000
JWT_SECRET=your-secret-key-change-in-production
CORS_ORIGIN=*
EOF

# Build Docker image
docker build -t cloud-nexus-backend .

# Run container
docker run -d \
  --name cloud-nexus-backend \
  -p 5000:5000 \
  --env-file .env \
  --restart always \
  cloud-nexus-backend

echo "Backend deployment complete"
