variable "ci_artifacts_bucket_name" {
  description = "S3 bucket name for CI artifacts"
  type        = string
  default     = "agents-cicd-artifacts"
}

resource "aws_s3_bucket" "ci_artifacts" {
  bucket = var.ci_artifacts_bucket_name
}

resource "aws_s3_bucket_public_access_block" "ci_artifacts" {
  bucket                  = aws_s3_bucket.ci_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ci_artifacts" {
  bucket = aws_s3_bucket.ci_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ci_artifacts" {
  bucket = aws_s3_bucket.ci_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ci_artifacts" {
  bucket = aws_s3_bucket.ci_artifacts.id

  rule {
    id     = "ci-artifacts-lifecycle"
    status = "Enabled"

    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 7
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
