variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cost_center" {
  description = "Cost center for tagging"
  type        = string
  default     = "devops"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "platform-team"
}

variable "env" {
  description = "Environment tag"
  type        = string
  default     = "nonprod"
}

variable "application" {
  description = "Application tag"
  type        = string
  default     = "agents-cicd"
}
