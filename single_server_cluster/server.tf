# A simple server with an EBS volume mounted on "/data".

# Ask Terraform to find our server's persistent "/data" volume, which
# stores actual data that we don't want to lose.
#
# Note that we do *not* create or manage this volume with Terraform.  If
# Terraform creates something, then it can also destroy it if we run the
# wrong command!  So for safety, we create this volume using the AWS web
# console, and manually mount it onto an instance for initial formatting.
# This also makes it easier to refactor our Terraform configuration in a
# major way without losing data.
data "aws_ebs_volume" "data" {
  # Look up the volume by name.
  filter {
    name   = "tag:Name"
    values = ["${var.name}:/data"]
  }
}

# Our actual server.
resource "aws_instance" "server" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  # The server must be in the same availability zone as the underlying EBS
  # volume.
  availability_zone           = "${data.aws_ebs_volume.data.availability_zone}"
  monitoring                  = true
  vpc_security_group_ids      = ["${var.vpc_security_group_id}"]
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.instance_profile.name}"
  key_name                    = "aldebaran-emk"
  
  # The user_data script will be run when the instance boots up.  This is
  # where we want to stick all customization and configuration, which
  # should be very minimal, because all the real work is done by ECS and
  # Docker.
  user_data = <<EOD
#!/bin/bash

# Fail immediately if there are errors.
set -euo pipefail  

# Configure our ECS cluster membership.  
echo ECS_CLUSTER="${var.ecs_cluster}" >> /etc/ecs/ecs.config

# Install tools needed for this script.
yum -y install aws-cli  

# Look up our instance ID using the AWS magic metadata address, and use it
# to attach our EBS volume.  Note that we tell this to mount as /dev/sdf, but
# it actually shows up as /dev/xvdf.
instance_id="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
aws ec2 --region ${var.aws_region} attach-volume \
  --volume-id ${data.aws_ebs_volume.data.id} \
  --instance-id  "$instance_id" \
  --device /dev/sdf

# Wait for the EBS volume to attach.
while [ ! -e /dev/xvdf ]; do sleep 1; done

# Create a mount point, add the volume to fstab, and mount it.
mkdir /data
echo "/dev/xvdf /data ext4 noatime 0 0" >> /etc/fstab
mount /data

# Restart Docker so that it sees /data, and make sure ECS is running after
# the Docker restart.
sudo service docker restart
sudo start ecs
  
# Apply the latest security updates.  We do this after setting up our
# volume, just in case some security update wants to start Docker.  We need
# to guarantee that Docker is started _after_ the volume is mounted, or
# containers may not see the volume.
yum -y update

# Turn on automatic security updates.  There's a chance this will totally
# break the server if an update goes wrong.  On the other hand, this server
# may run unattended for periods in the future, depending on who's
# administering it, so it's better to risk downtime than risk getting
# hacked.
#
# TODO: Configure automatic reboot after kernel updates?
yum -y install yum-cron  
EOD

  tags {
    Name = "${var.name}"
  }
}

# A stable IP address for our server which will survive reboots.  When the
# server is running, this is free.  When the server is stopped, this costs
# $3.60/month.
#
# We use this to prevent slow DNS updates from breaking access to the
# server, especially for our European users, who tend to see stale DNS
# records for a day or two longer than they should.
resource "aws_eip" "server" {
  instance = "${aws_instance.server.id}"
  vpc      = true
}
