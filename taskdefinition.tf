resource "aws_ecs_task_definition" "litellm_task" {
  family                   = "litellm-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.litellm_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "litellm"
      image     = "${aws_ecr_repository.litellm.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = 4000
        hostPort      = 4000
        protocol      = "tcp"
      }]
      memory      = var.ecs_memory
      cpu         = var.ecs_cpu
      networkMode = "awsvpc"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/litellm-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "LITELLM_MASTER_KEY", value = var.litellm_master_key },
        { name = "LITELLM_SALT_KEY", value = var.litellm_salt_key },
        { name = "DATABASE_URL", value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.litellm.endpoint}/${var.db_username}" },
        { name = "PROMETHEUS_MULTIPROC_DIR", value = "/prometheus_multiproc" }
      ]
      secrets = [
        { name = "AWS_ACCESS_KEY_ID", valueFrom = "${aws_secretsmanager_secret.aws_credentials.arn}:AWS_ACCESS_KEY_ID::" },
        { name = "AWS_SECRET_ACCESS_KEY", valueFrom = "${aws_secretsmanager_secret.aws_credentials.arn}:AWS_SECRET_ACCESS_KEY::" },
        { name = "OPENAI_API_KEY", valueFrom = "${aws_secretsmanager_secret.openai_key.arn}:OPENAI_API_KEY::" },
        { name = "ANTHROPIC_API_KEY", valueFrom = "${aws_secretsmanager_secret.anthropic_key.arn}:ANTHROPIC_API_KEY::" },
        { name = "AZURE_API_KEY", valueFrom = "${aws_secretsmanager_secret.azure_key.arn}:AZURE_API_KEY::" },
        { name = "GEMINI_API_KEY", valueFrom = "${aws_secretsmanager_secret.gemini_key.arn}:GEMINI_API_KEY::" }
      ]
    }
  ])
}
