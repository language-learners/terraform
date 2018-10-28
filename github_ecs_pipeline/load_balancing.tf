# Register this container with our AWS "application load balancer", which can
# serve multiple domains with certificates.

# Set up a "target group". The listeners on our load balancer can send requests
# to a target group, and an ECS service can register containers with this target
# group.
resource "aws_lb_target_group" "target_group" {
  name     = "${var.name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-5abfab3c"
}

# Add a rule to our listener directing traffic to our target group whenever the
# the domain matches.
resource "aws_lb_listener_rule" "proxy" {
  listener_arn = "${var.listener_arn}"
  priority     = "${var.listener_rule_priority}"

  # Send traffic to our target group.
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }

  # Match based on hostname.
  condition {
    field  = "host-header"
    values = ["${var.host}"]
  }
}

# Create a certificate for our domain.
resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.host}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a DNS record which shows that we control the domain, and authorize
# validate of the certificate.
resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

# Ask AWS to validate our certificate.
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

# Attach the certificate to our listener, so it can accept requests for that
# domain.
resource "aws_lb_listener_certificate" "cert" {
  listener_arn    = "${var.listener_arn}"
  certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
}

