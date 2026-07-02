variable "name_prefix" { type = string }
variable "repositories" { type = set(string) }
variable "image_retention_count" { type = number }
variable "tags" { type = map(string) }

