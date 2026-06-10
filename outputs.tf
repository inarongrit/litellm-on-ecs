output "alb_dns" {
  value = aws_lb.litellm.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.litellm.repository_url
}

output "grafana_endpoint" {
  value = aws_grafana_workspace.litellm.endpoint
}

output "prometheus_endpoint" {
  value = aws_prometheus_workspace.litellm.prometheus_endpoint
}
