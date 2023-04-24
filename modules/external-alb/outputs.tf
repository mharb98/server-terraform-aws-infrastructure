output "alb_id" {
  value = aws_lb.alb.id
}

output "alb_security_group" {
  value = aws_security_group.alb-security-group.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}
