# This defines the a reverse proxy service which handles:
#
# 1. Mapping multiple domains names each to the correct container.
# 2. Providing HTTPS support using Let's Encrypt.
#
# For more information, see:
#
# - https://github.com/lucaslorentz/caddy-docker-proxy
#
# We translate this configuration to Terraform + ECS task definition JSON. Also
# see the caddy.* labels which we add to the task definition JSON for each web
# container.
#
# We don't use a pipeline to build this, because everything we need is provided
# by prebuilt upstream images, so we can just go ahead and reuse those.

## An ECS service is in charge of making sure that our image gets run on the
## specified cluster.
#resource "aws_ecs_service" "service" {
#  name            = "reverse-proxy"
#  cluster         = "${aws_ecs_cluster.language_learners.name}"
#
#  # We only want to run one copy of this container.
#  desired_count   = 1
#
#  # Use the task definition we declare below.
#  task_definition = "${aws_ecs_task_definition.reverse_proxy.arn}"
#
#  # Don't try to run more than 100% of "desired_count" when updating the
#  # service.  This means we never have two copies of the proxy running at
#  # once, but it also means there will be a brief outage when deploying a
#  # new version.
#  deployment_maximum_percent = 100
#  deployment_minimum_healthy_percent = 0
#}
#
## Load our container definitions from a template file.
#data "template_file" "reverse_proxy_container_definitions" {
#  template = "${file("${path.module}/reverse-proxy-container-definitions.json")}"
#  vars {}
#}
#
## Declare our ECS task definition.
#resource "aws_ecs_task_definition" "reverse_proxy" {
#  family = "reverse-proxy"
#  container_definitions = "${data.template_file.reverse_proxy_container_definitions.rendered}"
#
#  # Define our volumes.  These are used to map directories on our
#  # EBS-backed `/data` volume to volume names referred to in our
#  # `*-container-definitions.json` file.
#  volume {
#    name = "docker-sock"
#    host_path = "/var/run/docker.sock"
#  }
#  volume {
#    name = "caddy"
#    host_path = "/data/caddy"
#  }
#}
