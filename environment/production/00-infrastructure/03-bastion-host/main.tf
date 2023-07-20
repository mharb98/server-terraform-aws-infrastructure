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

resource "aws_security_group" "production-bastion-sg" {
  name   = "${local.environment}-bastion-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "production-bastion-host" {
  ami                         = "ami-0b7fd829e7758b06d"
  key_name                    = "ec2-key-pair"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.production-bastion-sg.id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.vpc_public_subnets[1]
  associate_public_ip_address = true

  tags = {
    Name = "${local.environment}-bastion"
  }
}
