variable "name_prefix" { type = string }
variable "service_names" { type = list(string) }
variable "log_retention_in_days" { type = number }
variable "create_alarms" { type = bool }
variable "cluster_name" { type = string }
variable "alarm_actions" { type = list(string) }
variable "alb_arn_suffix" { type = string }
variable "cpu_threshold" { type = number }
variable "memory_threshold" { type = number }
variable "tags" { type = map(string) }

