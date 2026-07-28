data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  schedule_state = var.schedule_enabled ? "ENABLED" : "DISABLED"

  instance_arns = [
    for instance_id in var.instance_ids :
    "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${instance_id}"
  ]

  schedules = {
    start = {
      description = "Start the two EC2 web servers during business hours."
      expression  = var.start_schedule_expression
      api_action  = "startInstances"
    }
    stop = {
      description = "Stop the two EC2 web servers after business hours."
      expression  = var.stop_schedule_expression
      api_action  = "stopInstances"
    }
  }
}

# A dedicated schedule group keeps the lab resources organized.
resource "aws_scheduler_schedule_group" "this" {
  name = "${var.project_name}-group"
}

# EventBridge Scheduler assumes this role when it invokes the EC2 API.
resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeSchedulerToAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = aws_scheduler_schedule_group.this.arn
          }
        }
      }
    ]
  })
}

# The execution role can only start and stop the two EC2 instances provided as input.
resource "aws_iam_role_policy" "scheduler_ec2" {
  name = "${var.project_name}-ec2-start-stop"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StartAndStopSelectedInstances"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = local.instance_arns
      }
    ]
  })
}

# Universal targets call the EC2 StartInstances and StopInstances APIs directly.
resource "aws_scheduler_schedule" "ec2" {
  for_each = local.schedules

  name        = "${var.project_name}-${each.key}"
  group_name  = aws_scheduler_schedule_group.this.name
  description = each.value.description
  state       = local.schedule_state

  schedule_expression          = each.value.expression
  schedule_expression_timezone = var.schedule_timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:${data.aws_partition.current.partition}:scheduler:::aws-sdk:ec2:${each.value.api_action}"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = var.instance_ids
    })

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }
  }

  depends_on = [aws_iam_role_policy.scheduler_ec2]
}
