# Our global ECS-related setup.  ECS is the Amazon container-scheduling
# system, which is sort of like Kubernetes, but with a much smaller(!)
# learning curve and fewer features.  Fortunately, Amazon will do almost
# all the hard work for us.

# The main ECS cluster which we'll use to deploy our applications.
resource "aws_ecs_cluster" "language_learners" {
  name = "language-learners"
}

# Ask Terraform to query Amazon for the newest ECS-optimized AMI, which is
# the VM image that we'll use to boot our servers.  We use Amazon's own
# "ECS-optimized" AMIs, because these tend to be some of the most reliable
# and least buggy Docker setups out there.  Well, most of the time.
#
# See:
#
# https://www.terraform.io/docs/providers/aws/d/ami.html
# http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
# http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI_launch_latest.html
data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    # Note that sometimes Amazon ships a buggy ECS AMI.  I've seen them
    # maybe one time in 4 or 5 updates when deploying to staging clusters.
    # If this happens, you can replace the "*" below with the "2016.09.g"
    # of a known-good AMI.
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}
