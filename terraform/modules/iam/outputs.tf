output "task_execution_role_arn" { value = aws_iam_role.task_execution.arn }
output "task_role_arns" { value = { for name, role in aws_iam_role.task : name => role.arn } }

