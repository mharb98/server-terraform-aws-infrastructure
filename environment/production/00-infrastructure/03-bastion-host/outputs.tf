output "security_group_id" {
  description = "Security ID associated with the bastion host"
  value       = aws_security_group.production-bastion-sg.id
}
