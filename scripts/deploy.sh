#!/bin/bash

# INSECURE Deployment Script for Testing

set -e

# INSECURE: Hardcoded secrets in deployment script
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export DATABASE_URL=mysql://admin:password123@prod-db.example.com:3306/demo

# INSECURE: Logging secrets
echo "Deploying with AWS Key: $AWS_ACCESS_KEY_ID"
echo "Database URL: $DATABASE_URL"

# INSECURE: Downloading scripts from internet without verification
curl -s https://raw.githubusercontent.com/example/scripts/main/install.sh | bash

# INSECURE: Running commands with elevated privileges
sudo docker pull myapp:latest
sudo docker run -d --privileged --name myapp myapp:latest

# INSECURE: No input validation
if [ ! -z "$1" ]; then
    # INSECURE: Command injection vulnerability
    eval "docker exec myapp $1"
fi

# INSECURE: Leaving temporary files with secrets
echo "$AWS_SECRET_ACCESS_KEY" > /tmp/aws-secret
chmod 777 /tmp/aws-secret

# INSECURE: No cleanup
trap 'echo "Deployment failed"' ERR

echo "Deployment completed"

# INSECURE: API key in script
API_KEY="sk-1234567890abcdef1234567890abcdef"
curl -H "Authorization: Bearer $API_KEY" https://api.example.com/deploy