resource "aws_ecs_service" "litellm_service" {
  name            = "litellm-${var.environment}-service"
  cluster         = aws_ecs_cluster.litellm_cluster.id
  task_definition = aws_ecs_task_definition.litellm_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.litellm.arn
    container_name   = "litellm"
    container_port   = 4000
  }

  network_configuration {
    subnets = [
      aws_default_subnet.ecs_az1.id,
      aws_default_subnet.ecs_az2.id,
      aws_default_subnet.ecs_az3.id
    ]
    security_groups  = [aws_security_group.litellm.id]
    assign_public_ip = true
  }

  health_check_grace_period_seconds  = 300
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [aws_iam_role_policy_attachment.litellm_task_execution_role_policy, aws_lb_listener.litellm]

  tags = { Name = "litellm-${var.environment}-service" }
}
