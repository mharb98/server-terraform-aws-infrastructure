locals {
  environment = "production"
  app_name    = "demo"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/00-infrastructure/00-vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "bastion-host" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/00-infrastructure/00-bastion-host/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "external-alb" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/00-infrastructure/02-external-alb/terraform.tfstate"
    region = "eu-central-1"
  }
}

# External ALB target group
resource "aws_lb_target_group" "target-group" {
  name     = "${local.app_name}-${local.environment}-tg-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    enabled             = true
    interval            = 60
    matcher             = 200
    path                = "/"
    port                = 80
    protocol            = "http"
    timeout             = 30
    unhealthy_threshold = 5
  }
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

resource "aws_security_group" "ec2-security-group" {
  name        = "${local.environment}-ec2-security-group"
  description = "Allow HTTP traffic from alb"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description     = "HTTP traffic from anywhere"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.external-alb.outputs.alb-security-group-id]
  }

  ingress {
    description     = "SSH traffic from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.bastion-host.outputs.security_group_id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
  security_group_id  = aws_security_group.ec2-security-group.id
}
