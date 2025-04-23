#!/bin/bash

# Update system and install dependencies
yum update -y
yum install -y mysql
amazon-linux-extras install nginx1 -y
chkconfig nginx on

# Run everything else as ec2-user
su - ec2-user <<'EOF'
# Load NVM and install Node.js
export NVM_DIR="/home/ec2-user/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
. "$NVM_DIR/nvm.sh"
nvm install 16
nvm use 16

# Download the React app from S3
mkdir -p ~/web-tier
aws s3 cp s3://tf-project-9-code-bucket/web-tier/ ~/web-tier --recursive

# Install dependencies and build the app
cd ~/web-tier
npm install
npm run build || echo "React build failed" >> ~/build-failure.log
EOF

# Pull the corrected nginx.conf from the correct bucket
aws s3 cp s3://tf-project-9-code-bucket/nginx.conf /etc/nginx/nginx.conf

# Check and restart nginx
nginx -t && systemctl restart nginx

# Set proper permissions
chmod -R 755 /home/ec2-user
