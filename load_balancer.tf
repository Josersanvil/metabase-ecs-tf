locals {
  create_http_forward  = var.custom_load_balancer_arn == null ? var.route_53_domain_name == null ? true : false : false
  create_https_forward = var.custom_load_balancer_arn == null ? var.route_53_domain_name == null ? false : true : false
}

data "aws_route53_zone" "metabase-domain" {
  count = var.route_53_domain_name != null ? 1 : 0
  name  = var.route_53_domain_name
}

data "aws_lb" "custom_lb" {
  count = var.custom_load_balancer_arn == null ? 0 : 1
  arn   = var.custom_load_balancer_arn
}

resource "aws_lb_target_group" "metabase_target" {

  name                          = "metabase-web-target-${local.deployment_id}"
  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = "80"
  protocol                      = "HTTP"
  protocol_version              = "HTTP1"
  slow_start                    = "180"

  stickiness {
    cookie_duration = "86400"
    enabled         = "false"
    type            = "lb_cookie"
  }

  health_check {
    path                = "/api/health"
    matcher             = "200-299"
    healthy_threshold   = 3
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 3
  }

  target_type = "ip"
  vpc_id      = local.metabase_vpc_id
}

resource "aws_lb" "metabase-alb" {
  count = var.custom_load_balancer_arn == null ? 1 : 0

  name                       = "metabase-alb-${local.deployment_id}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.metabase_web_security_group.id]
  subnets                    = local.metabase_vpc_subnets_ids
  enable_deletion_protection = false
}

resource "aws_alb_listener" "http_forward" {
  count = local.create_http_forward ? 1 : 0

  load_balancer_arn = aws_lb.metabase-alb[0].id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.metabase_target.id
    type             = "forward"
  }
}

resource "aws_alb_listener" "http_redirect" {
  count = local.create_https_forward ? 1 : 0

  load_balancer_arn = aws_lb.metabase-alb[0].id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https_forward" {
  count = local.create_https_forward ? 1 : 0

  load_balancer_arn = aws_lb.metabase-alb[0].id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.metabase_domain[0].arn

  default_action {
    target_group_arn = aws_lb_target_group.metabase_target.id
    type             = "forward"
  }

  depends_on = [
    aws_acm_certificate_validation.metabase_domain_validation[0]
  ]
}

# Add dns record for the certificate validation:
resource "aws_acm_certificate" "metabase_domain" {
  count = local.create_https_forward ? 1 : 0

  domain_name       = var.subdomain_name != "" ? "${var.subdomain_name}.${var.route_53_domain_name}" : var.route_53_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "metabase_domain_validation" {
  count = local.create_https_forward ? 1 : 0

  name    = tolist(aws_acm_certificate.metabase_domain[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.metabase_domain[0].domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.metabase-domain[0].zone_id
  records = [
    tolist(aws_acm_certificate.metabase_domain[0].domain_validation_options)[0].resource_record_value
  ]
  ttl = 60
}

resource "aws_acm_certificate_validation" "metabase_domain_validation" {
  count = local.create_https_forward ? 1 : 0

  certificate_arn = aws_acm_certificate.metabase_domain[0].arn
  validation_record_fqdns = [
    aws_route53_record.metabase_domain_validation[0].fqdn
  ]
}

# Add dns record for the load balancer:

resource "aws_route53_record" "metabase-record" {
  count = var.route_53_domain_name != null ? 1 : 0

  name    = var.subdomain_name != "" ? "${var.subdomain_name}.${var.route_53_domain_name}" : var.route_53_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.metabase-domain[0].zone_id

  alias {
    evaluate_target_health = "true"
    name                   = var.custom_load_balancer_arn == null ? aws_lb.metabase-alb[0].dns_name : data.aws_lb.custom_lb[0].dns_name
    zone_id                = var.custom_load_balancer_arn == null ? aws_lb.metabase-alb[0].zone_id : data.aws_lb.custom_lb[0].zone_id
  }
}
