output "namespace_name" { value = aws_service_discovery_private_dns_namespace.this.name }
output "service_arns" { value = { for name, svc in aws_service_discovery_service.this : name => svc.arn } }

