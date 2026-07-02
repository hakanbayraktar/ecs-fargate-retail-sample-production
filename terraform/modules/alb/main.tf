resource "aws_lb" "this" {
  name               = substr(var.name, 0, 32)
  load_balancer_type = "application"
  internal           = false
  ip_address_type    = "dualstack"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_lb_target_group" "ui" {
  name                 = substr("${var.name}-ui", 0, 32)
  port                 = var.target_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
  }

  tags = merge(var.tags, { Name = "${var.name}-ui-tg" })
}

resource "aws_lb_listener" "http" {
  count             = var.certificate_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_route53_record" "this" {
  count   = var.route53_zone_id != null && var.public_domain_name != null ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.public_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ipv6" {
  count   = var.route53_zone_id != null && var.public_domain_name != null ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.public_domain_name
  type    = "AAAA"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
