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

resource "aws_db_subnet_group" "production-private-db-subnet-group" {
  name       = "production-db-subnet-group"
  subnet_ids = module.prod-vpc.vpc_private_subnets
}

resource "aws_lb_target_group" "production-target-group" {
  name     = "production-tg-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.prod-vpc.vpc_id
}

resource "aws_security_group" "bastion-sg" {
  name        = "bastion-hosts-security-group"
  description = "Allow SSH traffic from the internet"
  vpc_id      = module.prod-vpc.vpc_id
  ingress {
    description      = "SSH traffic from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    # security_groups = [var.alb_security_group]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "bastion-host" {
  ami             = "ami-0b7fd829e7758b06d" # us-west-2
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.bastion-sg.id]
  # vpc_id          = module.
  subnet_id = module.prod-vpc.vpc_public_subnets[0]
  # key_name = 
  #   network_interface {
  #     network_interface_id = aws_network_interface.foo.id
  #     device_index         = 0
  #   }

  #   credit_specification {
  #     cpu_credits = "unlimited"
  #   }
}

module "prod-secrets-manager" {
  source = "./modules/secrets"

  environment = "production"
  app_name    = "microservices"
  secrets     = jsonencode({ "DB_PASSWORD" : "12345678", "DB_USERNAME" : "marwan" })
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

module "prod-sql-database" {
  source = "./modules/sql-database"

  environment          = "production"
  app_name             = "microservices"
  vpc_id               = module.prod-vpc.vpc_id
  db_subnet_group_name = aws_db_subnet_group.production-private-db-subnet-group.id
  security_groups      = [module.prod-ec2-backend.backend-security-group]
  db_password          = module.prod-secrets-manager.secrets["DB_PASSWORD"]
  db_username          = module.prod-secrets-manager.secrets["DB_USERNAME"]
}

module "prod-backend-cloudfront-distribution" {
  source = "./modules/cloudfront-backend-alb-distribution"

  alb_dns_name = module.prod-external-alb.alb_dns_name
  environment  = "production"
  app_name     = "microservices"
}
