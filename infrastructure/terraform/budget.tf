variable "budget_amount_monthly" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 625.50
}

variable "budget_alert_emails" {
  description = "List of email addresses to notify on budget alerts"
  type        = list(string)
  default     = ["cloudship-ai@example.com"]
}

resource "aws_sns_topic" "cost_alerts" {
  name = "cost-alerts"
}

resource "aws_sns_topic_policy" "allow_budget" {
  arn    = aws_sns_topic.cost_alerts.arn
  policy = data.aws_iam_policy_document.budget_sns.json
}

data "aws_iam_policy_document" "budget_sns" {
  statement {
    sid = "AllowBudgetNotifications"
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cost_alerts.arn]
  }
}

resource "aws_sns_topic_subscription" "email_subs" {
  for_each  = toset(var.budget_alert_emails)
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_budgets_budget" "monthly" {
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.budget_amount_monthly
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  }
}
