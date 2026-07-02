variable "name" { type = string }
variable "service_name" { type = string }
variable "cluster_id" { type = string }
variable "cluster_name" { type = string }
variable "aws_region" { type = string }
variable "task_execution_role_arn" { type = string }
variable "task_role_arn" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "container_image" { type = string }
variable "container_port" { type = number }
variable "cpu" { type = number }
variable "memory" { type = number }
variable "desired_count" { type = number }
variable "deployment_minimum_healthy_percent" { type = number }
variable "deployment_maximum_percent" { type = number }
variable "load_balancer_target_group_arn" {
  type    = string
  default = null
}
variable "health_check_grace_period_seconds" {
  type    = number
  default = null
}
variable "service_discovery_service_arn" {
  type    = string
  default = null
}
variable "log_group_name" { type = string }
variable "environment" { type = map(string) }
variable "secrets" { type = map(string) }
variable "healthcheck_command" {
  type    = list(string)
  default = []
}
variable "tags" { type = map(string) }
