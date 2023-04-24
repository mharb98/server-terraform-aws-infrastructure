terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

module "prod-vpc" {
  source = "./modules/network"

  environment    = "production"
  vpc_cidr_block = "10.0.0.0/16"

  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

resource "aws_lb_target_group" "production-target-group" {
  name     = "production-tg-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.prod-vpc.vpc_id
}

module "prod-external-alb" {
  source           = "./modules/external-alb"
  environment      = "production"
  vpc_id           = module.prod-vpc.vpc_id
  subnet_ids       = module.prod-vpc.vpc_public_subnets
  target_group_arn = aws_lb_target_group.production-target-group.arn
}

module "prod-ec2-backend" {
  source = "./modules/ec2-backend"

  environment        = "production"
  app_name           = "microservices"
  vpc_id             = module.prod-vpc.vpc_id
  subnet_ids         = module.prod-vpc.vpc_private_subnets
  alb_id             = module.prod-external-alb.alb_id
  alb_security_group = module.prod-external-alb.alb_security_group
  tg_arn             = aws_lb_target_group.production-target-group.arn
}

module "prod-backend-cloudfront-distribution" {
  source = "./modules/cloudfront-backend-alb-distribution"

  alb_dns_name = module.prod-external-alb.alb_dns_name
  environment  = "production"
  app_name     = "microservices"
}
