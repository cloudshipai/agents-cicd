variable "log_group_names" {
  description = "CloudWatch log group names to manage retention for"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Default retention period in days"
  type        = number
  default     = 14
}

resource "aws_cloudwatch_log_group" "managed" {
  for_each          = toset(var.log_group_names)
  name              = each.key
  retention_in_days = var.log_retention_days
}
