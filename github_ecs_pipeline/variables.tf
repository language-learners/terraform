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

variable "github_oauth_token" {
  description = "The OAuth token used to access GitHub repositories."
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
