output "role_arn" {
  value = var.create ? aws_iam_role.this[0].arn : null
}
