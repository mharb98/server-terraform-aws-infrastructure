output "alb-id" {
  description = "ID of the external ALB"
  value       = aws_lb.alb.id
}

output "alb-dns-name" {
  description = "DNS name for external ALB"
  value       = aws_lb.alb.dns_name
}

output "alb-security-group-id" {
  description = "ID of the security group attached to the alb"
  value       = aws_security_group.alb-security-group.id
}
