variable "name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "node_type" { type = string }
variable "multi_az_enabled" { type = bool }
variable "automatic_failover_enabled" { type = bool }
variable "tags" { type = map(string) }

