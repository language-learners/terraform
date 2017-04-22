# Declare our "provider", which is the module that interfaces to a specific
# cloud like AWS.

provider "aws" {
  region = "${var.aws_region}"

  # You'll need to supply your security credentials on the command line.  DO
  # NOT CHECK THEM IN HERE OR TERRIBLE THINGS WILL HAPPEN ABOUT 5 SECONDS
  # AFTER THEY REACH GITHUB.
  #
  #    export AWS_ACCESS_KEY_ID="anaccesskey"
  #    export AWS_SECRET_ACCESS_KEY="asecretkey"
}
