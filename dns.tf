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
  records = ["34.204.9.245"]
  
  # Get the IP address of our Elastic IP.
  #records = ["${module.language_learners_server.public_ip}"]
}
