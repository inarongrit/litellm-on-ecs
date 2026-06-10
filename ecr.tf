resource "aws_ecr_repository" "litellm" {
  name         = "litellm-${var.environment}"
  force_delete = true
  tags = { Name = "litellm-${var.environment}-ecr" }
}
