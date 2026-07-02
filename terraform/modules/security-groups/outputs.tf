output "alb_sg_id" { value = aws_security_group.alb.id }
output "ui_sg_id" { value = aws_security_group.ui.id }
output "backend_sg_id" { value = aws_security_group.backend.id }
output "database_sg_id" { value = aws_security_group.database.id }
output "cache_sg_id" { value = aws_security_group.cache.id }

