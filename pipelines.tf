# This file defines all of our pipelines for building Docker images.  You
# should be able to add new ones by copying the examples here.

# The phpbb pipeline which builds our forum image.
module "phpbb_pipeline" {
  source = "github_ecs_pipeline"
  name = "phpbb"
  github_repo = "phpbb"
  github_branch = "custom"

  # Standard parameters which are the same for all pipelines.
  github_oauth_token = "${var.github_oauth_token}"
  aws_region = "${var.aws_region}"
  aws_account_id = "${var.aws_account_id}"
  pipeline_role_arn = "arn:aws:iam::771600087445:role/AWS-CodePipeline-Service"
  build_role_arn = "${aws_iam_role.codebuild_role.arn}"
  artifact_store_s3_bucket = "${aws_s3_bucket.codepipeline_artifacts.bucket}"
}

# The S3 bucket used to store the build artifacts created by CodePipeline.
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "llorg-codepipeline-artifacts"
  acl    = "private"
}

# The IAM role which allows our builds to access the necessary AWS resources.
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"
  path = "/service-role/"
  # Allow CodeBuild to assume this role. 
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# The security policy attached to our build role, which says which AWS
# resources it has permission to access.
resource "aws_iam_role_policy" "codebuild_role" {
  name = "build-policy"
  role = "${aws_iam_role.codebuild_role.id}"
  # This role was mostly auto-generated by the AWS web console, then fixed
  # up by hand a bit.
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/*",
                "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/*:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
            ],
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject"
            ]
        },
        {
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:GetAuthorizationToken",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }      
    ]
}
EOF
}