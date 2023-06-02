locals {
  environment = "production"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "marwan-harb-s3-terraform-state-backend"
    key    = "production/00-vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "security-groups" {
  backend = "s3"
  config = {
    bucket = "marwan-harb-s3-terraform-state-backend"
    key    = "production/04-security-groups/terraform.tfstate"
    region = "eu-central-1"
  }
}

# resource "aws_lb_target_group" "production-target-group" {
#   name     = "${local.environment}-tg-alb"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id
# }

resource "aws_lb" "alb" {
  name                             = "${local.environment}-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [data.terraform_remote_state.security-groups.outputs.alb-security-group-id]
  subnets                          = data.terraform_remote_state.vpc.outputs.vpc_public_subnets
  enable_cross_zone_load_balancing = true
}

# resource "aws_lb_listener" "http-listener" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.production-target-group.arn
#   }
# }
