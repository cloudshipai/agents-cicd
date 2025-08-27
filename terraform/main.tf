# AWS Infrastructure with Security Issues for Testing

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# S3 Bucket - INSECURE: Public read access
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "demo-security-test-bucket-${random_string.suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "demo_bucket" {
  bucket = aws_s3_bucket.demo_bucket.id

  # INSECURE: Allows public access
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "demo_bucket" {
  bucket = aws_s3_bucket.demo_bucket.id
  
  # INSECURE: Public read access
  acl = "public-read"
  
  depends_on = [aws_s3_bucket_ownership_controls.demo_bucket_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "demo_bucket_acl_ownership" {
  bucket = aws_s3_bucket.demo_bucket.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Security Group - INSECURE: Open to world
resource "aws_security_group" "web" {
  name        = "web-security-group"
  description = "Security group for web servers"

  # INSECURE: SSH open to world
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # INSECURE!
  }

  # INSECURE: HTTP open to world without HTTPS
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # INSECURE: Wide port range open
  ingress {
    description = "All ports"
    from_port   = 8000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # INSECURE!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance - INSECURE: Missing encryption
resource "aws_instance" "web" {
  ami           = "ami-0c94855ba95b798c7"  # Amazon Linux 2 in us-west-2
  instance_type = "t3.micro"
  
  # INSECURE: No encryption for EBS
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = false  # INSECURE!
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  # INSECURE: Hardcoded user data (could contain secrets)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Demo Web Server</h1>' > /var/www/html/index.html
              # INSECURE: Hardcoded API key (for testing secret detection)
              export API_KEY=sk-1234567890abcdef1234567890abcdef
              EOF
  )

  tags = {
    Name        = "demo-web-server"
    Environment = "testing"
    # INSECURE: Missing required tags for compliance
  }
}

# RDS Instance - INSECURE: Multiple issues
resource "aws_db_instance" "demo" {
  identifier = "demo-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  
  db_name  = "demo"
  username = "admin"
  password = "password123"  # INSECURE: Hardcoded password!
  
  # INSECURE: Not encrypted
  storage_encrypted = false
  
  # INSECURE: Public access
  publicly_accessible = true
  
  # INSECURE: No backup retention
  backup_retention_period = 0
  
  # INSECURE: Skip final snapshot
  skip_final_snapshot = true
  
  vpc_security_group_ids = [aws_security_group.database.id]
}

# Database Security Group - INSECURE: Open access
resource "aws_security_group" "database" {
  name        = "database-security-group" 
  description = "Security group for database"

  # INSECURE: MySQL open to world
  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # INSECURE!
  }
}

# IAM Policy - INSECURE: Overly permissive
resource "aws_iam_policy" "demo_policy" {
  name        = "demo-policy"
  description = "Demo policy with excessive permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # INSECURE: Wildcard permissions
        Effect = "Allow"
        Action = "*"  # INSECURE: All actions allowed!
        Resource = "*"  # INSECURE: All resources!
      },
    ]
  })
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.id
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "database_endpoint" {
  value = aws_db_instance.demo.endpoint
  # INSECURE: Sensitive output without sensitive flag
}