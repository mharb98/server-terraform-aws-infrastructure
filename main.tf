# # module "prod-secrets-manager" {
# #   source = "./modules/secrets"

# #   environment = "production"
# #   app_name    = "microservices"
# #   secrets     = jsonencode({ "DB_PASSWORD" : "12345678", "DB_USERNAME" : "marwan" })
# # }

# module "prod-backend-cloudfront-distribution" {
#   source = "./modules/cloudfront-backend-alb-distribution"

#   alb_dns_name = aws_lb.alb.dns_name
#   environment  = local.environment
#   app_name     = local.app_name
# }
