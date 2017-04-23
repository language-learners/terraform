variable "domain" {
  description = "The domain name for our site."
  default = "language-learners.org"
}

variable "domain_abbrev" {
  description = "An abbreviated form of the domain name, used for generating globally unique names for S3 buckets and other resources."
  default = "llorg"
}

variable "aws_account_id" {
  description = "The ID numbers of our AWS account."
  default = "771600087445"
}

variable "aws_region" {
  description = "The AWS region in which we're hosting the site."
  default = "us-east-1"
}
