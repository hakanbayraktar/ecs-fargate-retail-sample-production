variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "target_port" { type = number }
variable "health_check_path" { type = string }
variable "deregistration_delay" { type = number }
variable "certificate_arn" {
  type    = string
  default = null
}
variable "route53_zone_id" {
  type    = string
  default = null
}
variable "public_domain_name" {
  type    = string
  default = null
}
variable "tags" { type = map(string) }
