output "arn" { value = aws_lb.this.arn }
output "dns_name" { value = aws_lb.this.dns_name }
output "zone_id" { value = aws_lb.this.zone_id }
output "target_group_arn" { value = aws_lb_target_group.ui.arn }
output "arn_suffix" { value = aws_lb.this.arn_suffix }
output "url" { value = var.public_domain_name != null ? "https://${var.public_domain_name}" : "http://${aws_lb.this.dns_name}" }

