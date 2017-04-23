# The security roles for our server.  This is a custom, per-server security
# role because of issues with EBS volume security and ownership described
# below.

# Define an IAM role granting certain permissions to our server.
resource "aws_iam_role" "instance_role" {
  name = "${var.name}-instance-role"
  
  # Allow EC2 to assign this role to a server.
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# The permissions associated with our server's IAM role.
resource "aws_iam_role_policy" "instance_policy" {
  name = "instance-policy"
  role = "${aws_iam_role.instance_role.id}"

  # This is a bit of tricky security policy.  We want to allow this server
  # to attach and detach its own EBS volume, but we don't want to allow it
  # to touch any other EBS volumes belonging to other servers.  This helps
  # limit the damage caused by a compromised server.
  #
  # This is also why we define an individual security role for each server.
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:DetachVolume"
      ],
      "Resource": "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:instance/*",
      "Condition": {"StringEquals": {"ec2:ResourceTag/Name": "${var.name}"}}
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:CreateSnapshot"
      ],
      "Resource": "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:volume/*",
      "Condition": {"StringEquals": {"ec2:ResourceTag/Name": "${var.name}:/data"}}
    }
  ]
}
EOF
}

# We need to also attach Amazon's standard policy for instances running
# ECS, or we won't be allowed to register with our ECS cluster.
resource "aws_iam_policy_attachment" "ecs_attachment" {
  name       = "${var.name}-ecs-attachment"
  roles      = ["${aws_iam_role.instance_role.id}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# For some unknown reason, we need to package our role inside a profile and
# pass _that_ to EC2 to create the instance.
resource "aws_iam_instance_profile" "instance_profile" {
  name  = "${var.name}-instance-profile"
  role = "${aws_iam_role.instance_role.name}"
}
