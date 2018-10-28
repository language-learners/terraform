resource "aws_lb" "web_sites" {
  name               = "web-sites"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.load_balancer.id}"]
  subnets            = ["subnet-011dc549", "subnet-0f045d6a"]
}

resource "aws_lb_listener" "web_sites_https" {
  load_balancer_arn = "${aws_lb.web_sites.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_acm_certificate_validation.language_learners.certificate_arn}"

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

resource "aws_acm_certificate" "language_learners" {
  domain_name       = "language-learners.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "language_learners_validation" {
  name    = "${aws_acm_certificate.language_learners.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.language_learners.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  records = ["${aws_acm_certificate.language_learners.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "language_learners" {
  certificate_arn         = "${aws_acm_certificate.language_learners.arn}"
  validation_record_fqdns = ["${aws_route53_record.language_learners_validation.fqdn}"]
}
