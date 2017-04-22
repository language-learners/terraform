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
}
