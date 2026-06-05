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

# Install git
yum install git -y

# Create app directory
mkdir -p /opt/cloud-nexus-frontend
cd /opt/cloud-nexus-frontend

# Clone repository
git clone ${repo_url} .

# Create .env file
cat > .env << EOF
REACT_APP_API_URL=http://${backend_public_ip}:5000/api
REACT_APP_ENV=production
EOF

# Build Docker image
docker build -t cloud-nexus-frontend .

# Run container
docker run -d \
  --name cloud-nexus-frontend \
  -p 3000:3000 \
  --restart always \
  cloud-nexus-frontend

echo "Frontend deployment complete"
