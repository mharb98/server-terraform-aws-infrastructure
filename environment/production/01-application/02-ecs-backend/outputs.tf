output "security_group_id" {
  description = "Security group ID associated with the ecs task"
  value       = aws_security_group.ecs_task_sg.id
}
