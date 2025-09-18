terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      cost-center = var.cost_center
      owner       = var.owner
      env         = var.env
      application = var.application
      repo        = "cloudshipai/agents-cicd"
    }
  }
}
