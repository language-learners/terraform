# Our CodePipeline pipeline, which manages the build and deployment process.

resource "aws_codepipeline" "pipeline" {
  name     = "${var.name}"
  role_arn = "${var.pipeline_role_arn}"

  artifact_store {
    location = "${var.artifact_store_s3_bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["${var.name}"]

      configuration {
        Owner      = "language-learners"
        Repo       = "${var.github_repo}"
        Branch     = "${var.github_branch}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["${var.name}"]
      version         = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.build.name}"
      }
    }
  }

  // TODO: Deploy to a staging URL first?
  
  stage {
    name = "Approval"

    action {
      name            = "Approval"
      category        = "Approval"
      owner           = "AWS"
      provider        = "Manual"
      input_artifacts = []
      version         = "1"

      configuration {
        "NotificationArn" = "${var.notification_topic_arn}"
        # If we have a staging server, we could include a URL so that we could
        # check it out before approving.
        #"ExternalEntityLink" = "http://staging-${var.name}.language-learners.org/"
        "CustomData" = "A new ${var.name} image is ready to be deployed, but it requires manual approval."
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = []
      version         = "1"

      configuration {
        "FunctionName" = "ecs_deployer_lambda"
        # Pass these arguments in as a JSON string, because we can only
        # pass a string.  We'll parse them in the lambda code.
        "UserParameters" = <<EOD
{
  "ecsCluster": "${var.ecs_cluster}",
  "ecsService": "${var.name}",
  "ecsRegion": "${var.aws_region}"
}
EOD
      }
    }
  }
}
