# This defines the CodePipeline that builds and deploys our phpbb service.

# Use a module to do all the hard work.
module "phpbb_pipeline" {
  source = "github_ecs_pipeline"
  name = "phpbb"
  github_repo = "phpbb"
  github_branch = "custom"

  # Pass our taskdef information to the module.
  taskdef_family = "${aws_ecs_task_definition.phpbb.family}"
  taskdef_revision = "${aws_ecs_task_definition.phpbb.revision}"
  
  # Standard parameters which are the same for all pipelines.
  aws_region = "${var.aws_region}"
  aws_account_id = "${var.aws_account_id}"
  pipeline_role_arn = "${aws_iam_role.codepipeline_role.arn}"
  build_role_arn = "${aws_iam_role.codebuild_role.arn}"
  artifact_store_s3_bucket = "${aws_s3_bucket.codepipeline_artifacts.bucket}"
  ecs_cluster = "${aws_ecs_cluster.language_learners.name}"
  notification_topic_arn = "${aws_sns_topic.admin_updates.arn}"
}

# Load our container definitions from a template file.
data "template_file" "phpbb_container_definitions" {
  template = "${file("${path.module}/phpbb-container-definitions.json")}"
  vars {
    image = "771600087445.dkr.ecr.us-east-1.amazonaws.com/phpbb:latest"
  }
}

# Declare our ECS task definition for use by the pipeline.  The `family`
# field here must match the module's `name` above.
resource "aws_ecs_task_definition" "phpbb" {
  family = "phpbb"
  container_definitions = "${data.template_file.phpbb_container_definitions.rendered}"

  # Define our volumes.  These are used to map directories on our
  # EBS-backed `/data` volume to volume names referred to in our
  # `*-container-definitions.json` file.
  volume {
    name = "cache"
    host_path = "/data/phpbb/cache"
  }
  volume {
    name = "files"
    host_path = "/data/phpbb/files"
  }
  volume {
    name = "store"
    host_path = "/data/phpbb/store"
  }
  volume {
    name = "images"
    host_path = "/data/phpbb/images"
  }
  volume {
    name = "config-files"
    host_path = "/data/phpbb/config-files"
  }
}
