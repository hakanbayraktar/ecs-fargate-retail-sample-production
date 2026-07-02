output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "secret_version_arn" {
  value = aws_secretsmanager_secret_version.this.arn
}

