output "ec2-security-group-id" {
  description = "ID of the security group attached to the ec2 instances"
  value       = aws_security_group.ec2-security-group.id
}
