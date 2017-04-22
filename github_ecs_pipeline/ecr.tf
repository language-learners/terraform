# A repository for storing our Docker images.

resource "aws_ecr_repository" "repo" {
  name = "${var.name}"
}
