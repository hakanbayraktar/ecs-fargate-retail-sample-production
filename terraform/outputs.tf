output "aws_region" {
  description = "AWS region used by the environment."
  value       = var.aws_region
}

output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = module.alb.dns_name
}

output "application_url" {
  description = "Public URL for the UI service."
  value       = module.alb.url
}

output "https_enabled" {
  description = "Whether HTTPS is enabled on the public ALB."
  value       = module.alb.https_enabled
}

output "custom_domain_name" {
  description = "Configured public custom domain name, if any."
  value       = module.alb.custom_domain_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs_cluster.name
}

output "ecs_service_names" {
  description = "ECS service names by logical service."
  value = {
    ui       = module.ecs_service_ui.service_name
    catalog  = module.ecs_service_catalog.service_name
    cart     = module.ecs_service_cart.service_name
    checkout = module.ecs_service_checkout.service_name
    orders   = var.enable_orders ? module.ecs_service_orders[0].service_name : null
  }
}

output "ecs_task_definition_families" {
  description = "Task definition families by service."
  value = {
    ui       = module.ecs_service_ui.task_definition_family
    catalog  = module.ecs_service_catalog.task_definition_family
    cart     = module.ecs_service_cart.task_definition_family
    checkout = module.ecs_service_checkout.task_definition_family
    orders   = var.enable_orders ? module.ecs_service_orders[0].task_definition_family : null
  }
}

output "ecr_repository_urls" {
  description = "Private ECR repository URLs."
  value       = module.ecr.repository_urls
}

output "service_discovery_namespace" {
  description = "Cloud Map namespace name."
  value       = var.enable_service_discovery ? module.service_discovery[0].namespace_name : null
}

output "cart_dynamodb_table_name" {
  description = "Cart DynamoDB table name."
  value       = module.cart_dynamodb.table_name
}

output "github_actions_deploy_role_arn" {
  description = "Scoped GitHub Actions OIDC deploy role ARN for the environment."
  value       = module.github_actions_deploy_role.role_arn
}
