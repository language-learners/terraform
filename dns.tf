# Our DNS configuration.

# Our main DNS zone.
resource "aws_route53_zone" "primary" {
  name = "${var.domain}"
  comment = "Managed via https://github.com/language-learners/terraform/blob/master/dns.tf"
}

# Our "forum" record.
resource "aws_route53_record" "forum" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "forum"
  type    = "A"
  ttl     = "300"

  # For now, point this at a temporary server, until we finish migrating
  # completely onto this account.  Once the migration is done, delete this
  # and uncomment the records below.
  #records = ["34.204.9.245"]
  
  # Get the IP address of our server's Elastic IP.
  records = ["${module.language_learners_server.public_ip}"]
}

# A temporary "forum" record while we're migrating.
resource "aws_route53_record" "temp-forum" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "temp-forum"
  type    = "A"
  ttl     = "300"
  records = ["${module.language_learners_server.public_ip}"]
}

# An "old-forum" record while we're migrating.
resource "aws_route53_record" "old-forum" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "old-forum"
  type    = "A"
  ttl     = "300"
  records = ["34.204.9.245"]
}

# Our "www" record, still pointing to the old setup, but we'll update this
# soon to point to a Jekyll-based blog.
resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = ["how-to-learn-any-language.org"]
}

# Point the bare domain at an S3 bucket that automatically redirects (I think).
#
# TODO: Figure out what's going on here and move this to the new AWS
# account, too.
resource "aws_route53_record" "bare" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = ""
  type    = "A"

  alias {
    # This is a magic Amazon ALIAS target that turns S3 buckets into static
    # websites.
    name                   = "s3-website-us-east-1.amazonaws.com."
    zone_id                = "Z3AQBSTGFYJSTF"
    evaluate_target_health = false
  }
}

