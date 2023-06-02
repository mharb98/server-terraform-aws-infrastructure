# # module "prod-secrets-manager" {
# #   source = "./modules/secrets"

# #   environment = "production"
# #   app_name    = "microservices"
# #   secrets     = jsonencode({ "DB_PASSWORD" : "12345678", "DB_USERNAME" : "marwan" })
# # }

# # EC2 Backend
# resource "aws_security_group" "ec2-security-group" {
#   name        = "${local.environment}-${local.app_name}-ec2-security-group"
#   description = "Allow HTTP traffic from alb"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description     = "HTTP traffic from anywhere"
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb-security-group.id]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }
# }
# module "prod-ec2-backend" {
#   source = "./modules/ec2-backend"

#   environment        = local.environment
#   app_name           = local.app_name
#   vpc_id             = module.vpc.vpc_id
#   subnet_ids         = module.vpc.vpc_private_subnets
#   alb_id             = aws_lb.alb.id
#   alb_security_group = aws_lb.alb.id
#   tg_arn             = aws_lb_target_group.production-target-group.arn
#   security_group_id  = aws_security_group.ec2-security-group.id
# }

# module "prod-backend-cloudfront-distribution" {
#   source = "./modules/cloudfront-backend-alb-distribution"

#   alb_dns_name = aws_lb.alb.dns_name
#   environment  = local.environment
#   app_name     = local.app_name
# }
