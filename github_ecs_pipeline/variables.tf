# Input variables used to configure this module.

variable "name" {
  description = "The name of the pipeline, and the image it builds."
}

variable "github_repo" {
  description = "The name of the GitHub repository we build."
}

variable "github_branch" {
  description = "The branch we build."
  default = "master"
}

variable "aws_region" {
  description = "The AWS region in which our ECR repository is hosted."
}

variable "aws_account_id" {
  description = "The numeric ID of our AWS account."
}

variable "pipeline_role_arn" {
  description = "The IAM role for our pipeline."
}

variable "build_role_arn" {
  description = "The IAM role for our build."
}

variable "artifact_store_s3_bucket" {
  description = "The S3 bucket in which to store pipeline artifacts."
}

variable "ecs_cluster" {
  description = "The name of the ECS cluster on which to deploy this service."
}

variable "taskdef_family" {
  description = "The family name of the taskdef we use."
}

variable "taskdef_revision" {
  description = "The revision of the taskdef that we defined using Terraform.  Usually overriden by deployment pipelines."
}

variable "notification_topic_arn" {
  description = "The ARN of an SNS notification topic that will receive messages when something interesting happens."
}
