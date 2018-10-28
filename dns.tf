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

  alias {
    name                   = "${aws_lb.web_sites.dns_name}"
    zone_id                = "${aws_lb.web_sites.zone_id}"
    evaluate_target_health = false
  }
}

# Our "super-challenge" record.
resource "aws_route53_record" "super_challenge" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "super-challenge"
  type    = "A"

  alias {
    name                   = "${aws_lb.web_sites.dns_name}"
    zone_id                = "${aws_lb.web_sites.zone_id}"
    evaluate_target_health = false
  }
}

# An "old-forum" record while we're migrating.
resource "aws_route53_record" "old-forum" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "old-forum"
  type    = "A"
  ttl     = "300"
  records = ["34.204.9.245"]
}

# Our "www" record, pointing to a blog hosted on GitHub Pages.
resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = ["language-learners.github.io"]
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

