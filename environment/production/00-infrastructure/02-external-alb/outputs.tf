output "alb-id" {
  description = "ID of the external ALB"
  value       = aws_lb.alb.id
}

output "alb-dns-name" {
  description = "DNS name for external ALB"
  value       = aws_lb.alb.dns_name
}
