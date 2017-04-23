# Our CodePipeline pipeline, which manages the build and deployment process.

resource "aws_codepipeline" "pipeline" {
  name     = "${var.name}"
  role_arn = "${var.pipeline_role_arn}"

  artifact_store {
    location = "${var.artifact_store_s3_bucket}"
    type     = "S3"
  }

  # The "Source" stage is in charge of fetching our project's source code
  # from GitHub.
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

  # The "Build" stage turns our source code into a nicely-packaged Docker
  # image.  This relies on the AWS CodeBuild service and a `buildspec.yml`
  # file in the project which explains how to build it.  You should copy
  # the `buildspec.yml` file from the phpBB project; it does some tricky
  # stuff to tag the Docker images with the git commit ID.
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

  # TODO: Should we add a "StagingDeploy" stage, where we deploy to a test
  # server?  This would allow us to inspect how the new image is running
  # before deploying it.

  # The "Approval" stage shows a button in the web UI that we can click to
  # approve the changes.
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
        #"ExternalEntityLink" = "http://staging-${var.name}.${var.domain}/"
        "CustomData" = "A new ${var.name} image is ready to be deployed, but it requires manual approval."
      }
    }
  }

  # The "Deploy" stage uses a tiny JavaScript program (see the directory
  # "ecs_deployer_lambda") to generate a new ECS task definition and update
  # the ECS service that's in charge of finding a server on which to run
  # our code.  This will automatically cause the existing version to be
  # shut down and a new version to be spun up.
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
