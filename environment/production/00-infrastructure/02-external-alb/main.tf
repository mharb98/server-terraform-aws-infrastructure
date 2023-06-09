locals {
  environment = "production"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/00-infrastructure/00-vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_security_group" "alb-security-group" {
  name        = "${local.environment}-alb-security-group"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description      = "HTTP traffic from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "alb" {
  name                             = "${local.environment}-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb-security-group.id]
  subnets                          = data.terraform_remote_state.vpc.outputs.vpc_public_subnets
  enable_cross_zone_load_balancing = true
}
