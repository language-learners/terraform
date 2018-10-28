# We use an AWS Application Load Balancer to direct traffic to our various
# containers. This costs >=$21/month, but we tried various Docker proxy containers
# which were more trouble than they're worth.

# Our main load balancer, which handles all our websites.
resource "aws_lb" "web_sites" {
  name               = "web-sites"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.load_balancer.id}"]
  subnets            = ["subnet-011dc549", "subnet-0f045d6a"]
}

# Set up a listener on port 80, but just redirect everything to HTTPS.
resource "aws_lb_listener" "web_sites_http" {
  load_balancer_arn = "${aws_lb.web_sites.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Our HTTPS listener, which listens for HTTP requests. This doesn't do much by
# itself; look for the aws_lb_listener_rule declarations to see how requests
# actually get forwarded to the right server app.
resource "aws_lb_listener" "web_sites_https" {
  load_balancer_arn = "${aws_lb.web_sites.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  # This certificate isn't really used for anything useful, but we need to
  # specify one here.
  certificate_arn   = "${aws_acm_certificate_validation.language_learners.certificate_arn}"

  # This default action really shouldn't matter, because we don't use it for
  # anything.
  default_action {
    type = "redirect"
    redirect {
      host = "forum.language-learners.org"
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# An AWS security group describing the firewall rules for a load balancer.
resource "aws_security_group" "load_balancer" {
  name        = "load-balancer"
  description = "Allow HTTP and HTTPS traffic."

  # Allow inbound HTTP traffic.
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Declare a dummy certificate so we have a default certificate for the listener.
# Real certificates are attached to the aws_lb_listener_rule instead.
resource "aws_acm_certificate" "language_learners" {
  domain_name       = "language-learners.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a DNS record which proves that we control our domain and we want to
# issue a certificate, allowing AWS Certificate Manager to validate our
# certificate.
resource "aws_route53_record" "language_learners_validation" {
  name    = "${aws_acm_certificate.language_learners.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.language_learners.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  records = ["${aws_acm_certificate.language_learners.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

# Ask the AWS Certificate Manager to validate our certificate using the DNS
# entry we created.
resource "aws_acm_certificate_validation" "language_learners" {
  certificate_arn         = "${aws_acm_certificate.language_learners.arn}"
  validation_record_fqdns = ["${aws_route53_record.language_learners_validation.fqdn}"]
}
