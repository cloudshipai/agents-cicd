variable "ecr_repository_names" {
  description = "List of ECR repository names to apply lifecycle policies to"
  type        = list(string)
  default     = []
}

resource "aws_ecr_repository" "repos" {
  for_each = toset(var.ecr_repository_names)
  name     = each.key
}

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name
  policy     = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Retain last 10 images",
        selection    = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 10
        },
        action = { type = "expire" }
      },
      {
        rulePriority = 2,
        description  = "Expire untagged older than 7 days",
        selection    = {
          tagStatus     = "untagged",
          countType     = "sinceImagePushed",
          countUnit     = "days",
          countNumber   = 7
        },
        action = { type = "expire" }
      }
    ]
  })
}
