# Configuration options for this module.
#
# Note that we also look for an ECS volume named "${var.name}:/data" on the
# AWS account and mount it automatically.

variable "name" {
  description = "The name of this server."
}

variable "ami" {
  description = "The AMI (Amazon Machine Image) to use as the operating system."
}

variable "instance_type" {
  description = "The EC2 instance type to use for this machine."
  default = "t2.micro"
}

variable "vpc_security_group_id" {
  description = "The security group which controls what ports are accessible."
}

variable "ecs_cluster" {
  description = "The name of the ECS cluster which manages this server."
}

variable "aws_account_id" {
  description = "The numeric ID of our AWS account."
}

variable "aws_region" {
  description = "The region in which we're deploying our server."
}

  
