# Configuration of ECR (our Docker image repository) and ECS (our Docker
# cluster scheduler).

# An ECR repository holds multiple versions of a Docker image for us.
resource "aws_ecr_repository" "repo" {
  name = "${var.name}"
}

# We use a "data" block to fetch some information about the task definition
# at runtime.  Specifically, we want to know the current revision for use
# below.
data "aws_ecs_task_definition" "taskdef" {
  task_definition = "${var.taskdef_family}"
}

# An ECS service is in charge of making sure that our image gets run on the
# specified cluster.
resource "aws_ecs_service" "service" {
  name            = "${var.name}"
  cluster         = "${var.ecs_cluster}"

  # How many copies of this container do we want to run?
  desired_count   = "${var.desired_count}"

  # Wait a while for the application to start up.
  health_check_grace_period_seconds = "60"

  # This part is a bit tricky.  This first time we're run, we want to use
  # the basic task definition defined above.  But on subsequent runs, we
  # want to avoid clobbering the current task definition, which is supplied
  # by AWS CodePipeline.  So we use the "data" provider and "max" to get
  # the newest deployed version, and specify that.  This is based on
  # https://www.terraform.io/docs/providers/aws/d/ecs_task_definition.html
  task_definition = "${var.taskdef_family}:${max("${var.taskdef_revision}", "${data.aws_ecs_task_definition.taskdef.revision}")}"

  # Don't try to run more than 100% of "desired_count" when updating the
  # service.  This means we never have two copies of phpBB running at once,
  # but it also means there will be a brief outage when deploying a new
  # version.
  deployment_maximum_percent = 100
  deployment_minimum_healthy_percent = 0

  # Allow our ECS to talk to our load balancer on behalf of our service.
  iam_role = "arn:aws:iam::771600087445:role/ecsServiceRole"

  # Hook this up to our load balancer so we get web traffic.
  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    container_name = "${var.name}"
    container_port = 80
  }

  # Don't try to create this until our ALB listener actually has a validated
  # certificate assigned.
  depends_on = ["aws_lb_listener_certificate.cert"]
}
