variable "offhours_cron_weekdays" {
  description = "Cron expression for weekdays off-hours (UTC) e.g., 0 0-11,23 ? * MON-FRI *"
  type        = string
  default     = "0 0 0 ? * MON-FRI *"
}

variable "offhours_cron_weekends" {
  description = "Cron expression for weekends (UTC)"
  type        = string
  default     = "0 0 0 ? * SAT,SUN *"
}

variable "offhours_env_tags" {
  description = "Environments to target for off-hours (e.g., [\"dev\",\"stage\"])"
  type        = list(string)
  default     = ["dev", "stage"]
}

variable "schedule_tag_key" {
  description = "Tag key to enable offhours"
  type        = string
  default     = "schedule"
}

variable "schedule_tag_value" {
  description = "Tag value indicating offhours control"
  type        = string
  default     = "offhours"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "offhours" {
  name               = "offhours-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "offhours_policy" {
  statement {
    actions = ["ec2:DescribeInstances", "ec2:StopInstances", "ec2:StartInstances", "ec2:DescribeTags"]
    resources = ["*"]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "offhours" {
  name   = "offhours-scheduler-inline"
  role   = aws_iam_role.offhours.id
  policy = data.aws_iam_policy_document.offhours_policy.json
}

locals {
  lambda_code = <<PY
import boto3
import os

ec2 = boto3.client('ec2')

ENV_TAGS = set(os.getenv('ENV_TAGS','dev,stage').split(','))
SCHEDULE_TAG_KEY = os.getenv('SCHEDULE_TAG_KEY','schedule')
SCHEDULE_TAG_VAL = os.getenv('SCHEDULE_TAG_VAL','offhours')
ACTION = os.getenv('ACTION','stop') # 'stop' or 'start'

def handler(event, context):
    filters = [
        {'Name': f'tag:{SCHEDULE_TAG_KEY}', 'Values': [SCHEDULE_TAG_VAL]},
        {'Name': 'instance-state-name', 'Values': ['running' if ACTION=='stop' else 'stopped']}
    ]
    resp = ec2.describe_instances(Filters=filters)
    instances = []
    for r in resp.get('Reservations', []):
        for i in r.get('Instances', []):
            tags = {t['Key']: t['Value'] for t in i.get('Tags', [])}
            if tags.get('env') in ENV_TAGS:
                instances.append(i['InstanceId'])
    if instances:
        if ACTION == 'stop':
            ec2.stop_instances(InstanceIds=instances)
        else:
            ec2.start_instances(InstanceIds=instances)
    return {'action': ACTION, 'instances': instances}
PY
}

resource "aws_lambda_function" "offhours" {
  function_name = "offhours-scheduler"
  role          = aws_iam_role.offhours.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "offhours.zip"

  source_code_hash = filebase64sha256("offhours.zip")

  environment {
    variables = {
      ENV_TAGS         = join(",", var.offhours_env_tags)
      SCHEDULE_TAG_KEY = var.schedule_tag_key
      SCHEDULE_TAG_VAL = var.schedule_tag_value
      ACTION           = "stop"
    }
  }

  depends_on = [aws_iam_role_policy.offhours]
}

resource "null_resource" "offhours_zip" {
  provisioner "local-exec" {
    command = <<EOT
set -e
mkdir -p .terraform-local
cat > .terraform-local/index.py <<'PY'
${local.lambda_code}
PY
cd .terraform-local && zip -q ../offhours.zip index.py
EOT
  }
}

resource "aws_cloudwatch_event_rule" "offhours_weekdays" {
  name                = "offhours-weekdays"
  schedule_expression = "cron(0 23 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "offhours_weekends" {
  name                = "offhours-weekends"
  schedule_expression = "cron(0 23 ? * SAT,SUN *)"
}

resource "aws_cloudwatch_event_target" "offhours_weekdays" {
  rule      = aws_cloudwatch_event_rule.offhours_weekdays.name
  target_id = "offhours-lambda"
  arn       = aws_lambda_function.offhours.arn
}

resource "aws_cloudwatch_event_target" "offhours_weekends" {
  rule      = aws_cloudwatch_event_rule.offhours_weekends.name
  target_id = "offhours-lambda"
  arn       = aws_lambda_function.offhours.arn
}

resource "aws_lambda_permission" "allow_events_weekdays" {
  statement_id  = "AllowExecutionFromEventsWeekdays"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.offhours.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.offhours_weekdays.arn
}

resource "aws_lambda_permission" "allow_events_weekends" {
  statement_id  = "AllowExecutionFromEventsWeekends"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.offhours.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.offhours_weekends.arn
}
