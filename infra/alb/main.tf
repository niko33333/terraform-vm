locals {
  projectName = var.project_name
  environment = var.env
  prefix      = "${local.projectName}-${local.environment}"
  common_tags = {
      projectName = local.projectName
      environment = local.environment
  }
}

resource "aws_security_group" "alb_security_group" {
  name        = "${local.prefix}-alb-sg"
  description = "Security group for alb in ${var.env}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-alb-sg"
    }
  )

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "public_alb" {
  name               = "${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  subnets         = var.alb_subnet_list
  security_groups = [aws_security_group.alb_security_group.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-alb"
    }
  )
}

resource "aws_lb_target_group" "alb_tg" {
  name = "${local.prefix}-tg"

  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  slow_start = 120

  health_check {
    path                = "/"
    timeout             = 5
    interval            = 120
    healthy_threshold   = 2
    unhealthy_threshold = 6
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-tg"
    }
  )
}

resource "aws_lb_listener" "http_to_https" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}
