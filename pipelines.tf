# Share declarations used by all pipelines.  For the individual pipelines,
# look in the `*_pipeline.tf` files.

# The ECS cluster which we'll use to deploy our applications.
resource "aws_ecs_cluster" "language_learners" {
  name = "language-learners"
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
        },
        {
            "Action": [
                "codepipeline:GetPipelineState",
                "codepipeline:GetPipelineExecution"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }      
    ]
}
EOF
}
