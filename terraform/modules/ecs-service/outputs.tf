output "service_name" { value = aws_ecs_service.this.name }
output "cluster_name" { value = var.cluster_name }
output "task_definition_family" { value = aws_ecs_task_definition.this.family }
output "service_arn" { value = aws_ecs_service.this.id }
output "task_definition_arn" { value = aws_ecs_task_definition.this.arn }
