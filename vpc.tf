resource "aws_default_vpc" "ecs-vpc" {
  tags = {
    Name = "ECS-VPC"
  }
}

resource "aws_default_subnet" "ecs_az1" {
  availability_zone = var.availability_zones[0]
  tags = { Name = "Default subnet for ${var.availability_zones[0]}" }
}

resource "aws_default_subnet" "ecs_az2" {
  availability_zone = var.availability_zones[1]
  tags = { Name = "Default subnet for ${var.availability_zones[1]}" }
}

resource "aws_default_subnet" "ecs_az3" {
  availability_zone = var.availability_zones[2]
  tags = { Name = "Default subnet for ${var.availability_zones[2]}" }
}

resource "aws_security_group" "litellm" {
  name        = "litellm-${var.environment}-ecs-sg"
  description = "Allow inbound traffic to LiteLLM"
  vpc_id      = aws_default_vpc.ecs-vpc.id

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "litellm-${var.environment}-ecs-sg" }
}
