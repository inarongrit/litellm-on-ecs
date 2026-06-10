resource "aws_ecs_cluster" "litellm_cluster" {
  name = "litellm-${var.environment}-cluster"
}
