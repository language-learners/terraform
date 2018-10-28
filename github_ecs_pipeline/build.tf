# The builder that performs the build on behalf of the pipeline.

resource "aws_codebuild_project" "build" {
  name          = "${var.name}"
  description   = "Build ECR image for ${var.name}"
  build_timeout = "10"
  service_role  = "${var.build_role_arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/docker:1.12.1"
    type         = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "IMAGE_REPO_NAME"
      "value" = "${var.name}"
    }

    environment_variable {
      "name"  = "AWS_DEFAULT_REGION"
      "value" = "${var.aws_region}"
    }

    environment_variable {
      "name"  = "AWS_ACCOUNT_ID"
      "value" = "${var.aws_account_id}"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}
