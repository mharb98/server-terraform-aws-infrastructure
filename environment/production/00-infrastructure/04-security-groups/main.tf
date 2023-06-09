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

resource "aws_security_group" "ec2-security-group" {
  name        = "${local.environment}-ec2-security-group"
  description = "Allow HTTP traffic from alb"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description     = "HTTP traffic from anywhere"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-security-group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
