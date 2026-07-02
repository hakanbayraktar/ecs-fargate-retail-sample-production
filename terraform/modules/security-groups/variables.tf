variable "name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr_block" { type = string }
variable "alb_ingress_cidrs" { type = list(string) }
variable "ui_container_port" { type = number }
variable "backend_container_port" { type = number }
variable "tags" { type = map(string) }

