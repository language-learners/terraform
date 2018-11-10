# Our servers.  We define these using the "single_server_cluster" module,
# which automatically hooks each server up to the appropriate EBS cluster.

# Our main forum server at language-learners.org.
module "language_learners_server" {
  source = "single_server_cluster"

  name                  = "language-learners"
  ami                   = "${data.aws_ami.ecs_ami.id}"
  instance_type         = "t2.small"
  ecs_cluster           = "${aws_ecs_cluster.language_learners.name}"
  vpc_security_group_id = "${aws_security_group.web_server.id}"

  # Standard configuration shared with all instances.
  aws_region     = "${var.aws_region}"
  aws_account_id = "${var.aws_account_id}"
}

# An AWS security group describing the firewall rules for a basic web server.
resource "aws_security_group" "web_server" {
  name        = "web-server"
  description = "Allow HTTP, HTTPS and SSH traffic."

  # Allow inbound SSH traffic.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound container traffic.
  ingress {
    # This is supposedly the port range for automatically assigned ports.
    from_port   = 32768
    to_port     = 61000
    protocol    = "tcp"
    //security_groups = ["${aws_security_group.load_balancer.id}"]
    cidr_blocks = ["172.31.0.0/16"]
  }

  # Allow all outbound traffic.
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
