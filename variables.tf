variable "project_name" {
  description = "Short name used to identify the resources created by this lab."
  type        = string
  default     = "ec2-scheduler-lab"

}

variable "aws_region" {
  description = "AWS Region where the EC2 instances and EventBridge Scheduler resources are located."
  type        = string
  default     = "us-east-1"
}

variable "instance_ids" {
  description = "Exactly two EC2 instance IDs that EventBridge Scheduler will start and stop."
  type        = list(string)

  validation {
    condition = (
      length(var.instance_ids) == 2 &&
      alltrue([
        for instance_id in var.instance_ids :
        can(regex("^i-([0-9a-f]{8}|[0-9a-f]{17})$", instance_id))
      ])
    )
    error_message = "instance_ids must contain exactly two valid EC2 instance IDs."
  }
}

variable "schedule_timezone" {
  description = "IANA time zone used to evaluate the start and stop schedules."
  type        = string
  default     = "America/Lima"
}

variable "start_schedule_expression" {
  description = "EventBridge Scheduler cron expression used to start the EC2 instances."
  type        = string
  default     = "cron(0 8 ? * MON-SAT *)"
}

variable "stop_schedule_expression" {
  description = "EventBridge Scheduler cron expression used to stop the EC2 instances."
  type        = string
  default     = "cron(0 21 ? * MON-SAT *)"
}

variable "schedule_enabled" {
  description = "Whether the EventBridge schedules are enabled. Keep false during the first review."
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags applied to supported AWS resources."
  type        = map(string)
  default     = {}
}
