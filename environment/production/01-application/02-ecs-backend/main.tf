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

data "terraform_remote_state" "external-alb" {
  backend = "s3"
  config = {
    bucket = "marwan-s3-terraform-state-backend"
    key    = "production/00-infrastructure/02-external-alb/terraform.tfstate"
    region = "eu-central-1"
  }
}

# ALB configurations
resource "aws_lb_target_group" "target-group" {
  name        = "ecs-${local.app_name}-${local.environment}-tg-alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "ip"
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

# ECS configurations
/* 
  ECS needs two types of roles
  1.Task execution role => The role that is used for running the task and pulling the image from ECR
  2.Task role => The role that is attached to the service itself when an instance is spinned up (given database access, cache, ...etc)
*/
# Defining the task execution role
resource "aws_iam_role" "ecs-task-execution-role" {
  name = "${local.app_name}-ecs-task-execution-role"

  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Defining the task definition role
resource "aws_iam_role" "ecs-task-role" {
  name = "${local.app_name}-${local.environment}-ecs-task-role"

  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
    }
  EOF
}

resource "aws_iam_policy" "task-definition-iam-policy" {
  name        = "${local.app_name}-${local.environment}-task-policy"
  description = "Policy that allows access for ecs task definition"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "rds-db:connect"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = aws_iam_policy.task-definition-iam-policy.arn
}


# Defining the security group that will be attached to the services in ecs cluster (will only accept http traffic from alb)
resource "aws_security_group" "ecs_task_sg" {
  name   = "${local.environment}-${local.app_name}-ecs-task-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.external-alb.outputs.alb-security-group-id]
  }
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [data.terraform_remote_state.external-alb.outputs.alb-security-group-id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Defining the ecs module
module "ecs-backend" {
  source                      = "../../../../modules/ecs-backend"
  app_name                    = "demo"
  environment                 = "production"
  subnets                     = data.terraform_remote_state.vpc.outputs.vpc_private_subnets
  alb_tg_arn                  = aws_lb_target_group.target-group.arn
  service_security_group_id   = aws_security_group.ecs_task_sg.id
  ecs_task_execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
  task_role_arn               = aws_iam_role.ecs-task-role.arn
}
