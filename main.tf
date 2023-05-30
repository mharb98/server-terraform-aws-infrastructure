terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  environment = "production"
  app_name    = "microservices"
}

# VPC
module "vpc" {
  source = "./modules/network"

  environment    = local.environment
  vpc_cidr_block = "10.0.0.0/16"

  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

// ALB
resource "aws_security_group" "alb-security-group" {
  name        = "${local.environment}-alb-security-group"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = module.vpc.vpc_id

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
resource "aws_lb_target_group" "production-target-group" {
  name     = "${local.environment}-tg-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}
resource "aws_lb" "alb" {
  name                             = "${local.environment}-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb-security-group.id]
  subnets                          = module.vpc.vpc_public_subnets
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.production-target-group.arn
  }
}

# Bastion host
resource "aws_security_group" "production-bastion-sg" {
  name   = "${local.environment}-bastion-sg"
  vpc_id = module.vpc.vpc_id

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
  subnet_id                   = module.vpc.vpc_public_subnets[0]
  associate_public_ip_address = true

  tags = {
    Name = "production-bastion"
  }
}


# module "prod-secrets-manager" {
#   source = "./modules/secrets"

#   environment = "production"
#   app_name    = "microservices"
#   secrets     = jsonencode({ "DB_PASSWORD" : "12345678", "DB_USERNAME" : "marwan" })
# }

# EC2 Backend
resource "aws_security_group" "ec2-security-group" {
  name        = "${local.environment}-${local.app_name}-ec2-security-group"
  description = "Allow HTTP traffic from alb"
  vpc_id      = module.vpc.vpc_id

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
module "prod-ec2-backend" {
  source = "./modules/ec2-backend"

  environment        = local.environment
  app_name           = local.app_name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.vpc_private_subnets
  alb_id             = aws_lb.alb.id
  alb_security_group = aws_lb.alb.id
  tg_arn             = aws_lb_target_group.production-target-group.arn
  security_group_id  = aws_security_group.ec2-security-group.id
}

# Database
resource "aws_security_group" "db-security-group" {
  name = "${local.environment}-db-sg"

  description = "Security group to allow access from ec2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic from ec2 instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-security-group.id]
  }
}
resource "aws_db_subnet_group" "private-db-subnet-group" {
  name       = "${local.environment}-db-subnet-group"
  subnet_ids = module.vpc.vpc_private_subnets
}

resource "aws_db_instance" "db-instance" {
  allocated_storage      = 10
  db_name                = "marwan"
  engine                 = "postgres"
  engine_version         = "10"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.private-db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.db-security-group.id]
  username               = "marwan"
  password               = "marwan12"
}

module "prod-backend-cloudfront-distribution" {
  source = "./modules/cloudfront-backend-alb-distribution"

  alb_dns_name = aws_lb.alb.dns_name
  environment  = local.environment
  app_name     = local.app_name
}
