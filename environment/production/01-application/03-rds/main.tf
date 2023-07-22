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

data "terraform_remote_state" "ecs-backend" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/01-application/02-ecs-backend/terraform.tfstate"
    region = "eu-central-1"
  }
}


data "terraform_remote_state" "ec2-backend" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/01-application/01-ec2-backend/terraform.tfstate"
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


resource "aws_security_group" "db-security-group" {
  name = "${local.environment}-db-sg"

  description = "Security group to allow access from ec2 instances"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow traffic from all ips mainly (ec2/bastion-hosts)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      data.terraform_remote_state.ec2-backend.outputs.ec2-security-group-id,
      data.terraform_remote_state.bastion-host.outputs.security_group_id,
    data.terraform_remote_state.ecs-backend.outputs.security_group_id]
  }
}

resource "aws_db_subnet_group" "private-db-subnet-group" {
  name       = "${local.environment}-db-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.vpc_private_subnets
}

resource "aws_db_instance" "db-instance" {
  allocated_storage      = 10
  db_name                = "database_demo"
  engine                 = "postgres"
  engine_version         = "11"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.private-db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.db-security-group.id]
  skip_final_snapshot    = true
  username               = "postgres"
  password               = "marwan12"
}
