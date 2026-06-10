resource "aws_security_group" "alb" {
  name        = "litellm-${var.environment}-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = aws_default_vpc.ecs-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "litellm-${var.environment}-alb-sg" }
}

resource "aws_lb" "litellm" {
  name               = "litellm-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_default_subnet.ecs_az1.id,
    aws_default_subnet.ecs_az2.id,
    aws_default_subnet.ecs_az3.id
  ]

  tags = { Name = "litellm-${var.environment}-alb" }
}

resource "aws_lb_target_group" "litellm" {
  name        = "litellm-${var.environment}-tg"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.ecs-vpc.id
  target_type = "ip"

  health_check {
    path                = "/health/liveliness"
    port                = "4000"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
  }

  tags = { Name = "litellm-${var.environment}-tg" }
}

resource "aws_lb_listener" "litellm" {
  load_balancer_arn = aws_lb.litellm.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.litellm.arn
  }
}
