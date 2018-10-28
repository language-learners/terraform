# This defines the CodePipeline that builds and deploys our Super Challenge
# service.

# Use a module to do all the hard work.
module "superchallengebot_pipeline" {
  source = "github_ecs_pipeline"
  name = "superchallengebot"
  host = "super-challenge.language-learners.org"
  github_repo = "superchallengebot"
  github_branch = "master"
  listener_rule_priority = 100

  # Pass our taskdef information to the module.
  taskdef_family = "${aws_ecs_task_definition.superchallengebot.family}"
  taskdef_revision = "${aws_ecs_task_definition.superchallengebot.revision}"

  # Standard parameters which are the same for all pipelines.
  aws_region = "${var.aws_region}"
  aws_account_id = "${var.aws_account_id}"
  pipeline_role_arn = "${aws_iam_role.codepipeline_role.arn}"
  build_role_arn = "${aws_iam_role.codebuild_role.arn}"
  artifact_store_s3_bucket = "${aws_s3_bucket.codepipeline_artifacts.bucket}"
  ecs_cluster = "${aws_ecs_cluster.language_learners.name}"
  notification_topic_arn = "${aws_sns_topic.admin_updates.arn}"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  listener_arn = "${aws_lb_listener.web_sites_https.arn}"
}

# Load our container definitions from a template file.
data "template_file" "superchallengebot_container_definitions" {
  template = "${file("${path.module}/superchallengebot-container-definitions.json")}"
  vars {
    image = "771600087445.dkr.ecr.us-east-1.amazonaws.com/superchallengebot:latest"
  }
}

# Declare our ECS task definition for use by the pipeline.  The `family`
# field here must match the module's `name` above.
resource "aws_ecs_task_definition" "superchallengebot" {
  family = "superchallengebot"
  container_definitions = "${data.template_file.superchallengebot_container_definitions.rendered}"

  # Define our volumes.  These are used to map directories on our
  # EBS-backed `/data` volume to volume names referred to in our
  # `*-container-definitions.json` file.
  volume {
    name = "config-files"
    host_path = "/data/superchallengebot/config-files"
  }
}
