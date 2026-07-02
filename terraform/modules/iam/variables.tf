variable "name_prefix" { type = string }
variable "service_names" { type = list(string) }
variable "cart_dynamodb_table_arn" { type = string }
variable "execution_secret_arns" { type = list(string) }
variable "tags" { type = map(string) }

