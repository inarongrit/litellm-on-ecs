resource "aws_security_group" "rds" {
  name        = "litellm-${var.environment}-rds-sg"
  description = "Allow ECS tasks to connect to RDS"
  vpc_id      = aws_default_vpc.ecs-vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.litellm.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "litellm-${var.environment}-rds-sg" }
}

resource "aws_db_subnet_group" "litellm" {
  name = "litellm-${var.environment}-db-subnet"
  subnet_ids = [
    aws_default_subnet.ecs_az1.id,
    aws_default_subnet.ecs_az2.id,
    aws_default_subnet.ecs_az3.id
  ]
  tags = { Name = "litellm-${var.environment}-db-subnet" }
}

resource "aws_db_instance" "litellm" {
  identifier             = "litellm-${var.environment}-db"
  engine                 = "postgres"
  engine_version         = "16.9"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = "litellm"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.litellm.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = { Name = "litellm-${var.environment}-db" }
}
