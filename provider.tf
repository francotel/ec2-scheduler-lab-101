provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project   = var.project_name
        ManagedBy = "Terraform"
        Lab       = "EC2-Scheduler-101"
      },
      var.additional_tags
    )
  }
}
