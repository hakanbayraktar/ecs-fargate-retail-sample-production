variable "name" { type = string }
variable "vpc_id" { type = string }
variable "service_names" { type = list(string) }
variable "tags" { type = map(string) }

