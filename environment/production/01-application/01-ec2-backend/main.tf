locals {
  environment = "production"
  app_name    = "demo"
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

data "terraform_remote_state" "external-alb" {
  backend = "s3"
  config = {
    bucket = "marwan-harb-s3-terraform-state-backend"
    key    = "production/02-external-alb/terraform.tfstate"
    region = "eu-central-1"
  }
}

# External ALB target group
resource "aws_lb_target_group" "target-group" {
  name     = "${local.app_name}-${local.environment}-tg-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = data.terraform_remote_state.external-alb.outputs.alb-id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

# EC2 backend declaration
module "prod-ec2-backend" {
  source = "../../../../modules/ec2-backend"

  environment        = local.environment
  app_name           = local.app_name
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.vpc.outputs.vpc_private_subnets
  alb_id             = data.terraform_remote_state.external-alb.outputs.alb-id
  alb_security_group = data.terraform_remote_state.external-alb.outputs.alb-id
  tg_arn             = aws_lb_target_group.target-group.arn
  security_group_id  = data.terraform_remote_state.security-groups.outputs.ec2-security-group-id
}
