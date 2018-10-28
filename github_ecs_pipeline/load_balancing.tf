# Register this container with our AWS "application load balancer", which can
# serve multiple domains with certificates.

resource "aws_lb_target_group" "target_group" {
  name     = "${var.name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-5abfab3c"
}

resource "aws_lb_listener_rule" "proxy" {
  listener_arn = "${var.listener_arn}"
  priority     = "${var.listener_rule_priority}"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.host}"]
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.host}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

resource "aws_lb_listener_certificate" "cert" {
  listener_arn    = "${var.listener_arn}"
  certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
}

