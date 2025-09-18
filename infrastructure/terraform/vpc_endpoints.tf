variable "vpc_id" {
  description = "VPC ID for gateway endpoints"
  type        = string
  default     = ""
}

variable "route_table_ids" {
  description = "List of route table IDs for gateway endpoints"
  type        = list(string)
  default     = []
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.vpc_id != "" && length(var.route_table_ids) > 0 ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.route_table_ids
  tags = {
    Name = "s3-gateway-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.vpc_id != "" && length(var.route_table_ids) > 0 ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.route_table_ids
  tags = {
    Name = "dynamodb-gateway-endpoint"
  }
}
