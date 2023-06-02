output "ec2-security-group-id" {
  description = "ID for security group attached to ec2 backend instances"
  value       = aws_security_group.ec2-security-group.id
}

output "alb-security-group-id" {
  description = "ID for security groups attached to alb"
  value       = aws_security_group.alb-security-group.id
}
