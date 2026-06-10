resource "aws_cloudwatch_log_group" "litellm_ecs" {
  name              = "/ecs/litellm-${var.environment}"
  retention_in_days = 30
  tags = { Name = "litellm-${var.environment}-logs" }
}
