variable "create" {
  type    = bool
  default = true
}

variable "name" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_environment" {
  type = string
}

variable "github_oidc_provider_arn" {
  type = string
}

variable "ecr_repository_arns" {
  type = list(string)
}

variable "service_arns" {
  type = list(string)
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arns" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
