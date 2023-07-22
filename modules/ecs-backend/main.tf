provider "aws" {
  region = "eu-central-1"
}

# The repository from which the ecs services will pull the image
# resource "aws_ecr_repository" "repository" {
#   name = "ecs-${var.environment}-${var.app_name}"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# The cluster that will hold the task definitions and services
resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-cluster"
}

# The template from which the services will be created
resource "aws_ecs_task_definition" "aws-ecs-task" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      "name" : "${var.app_name}",
      "image" : "${var.repository_name}",
      "entryPoint" : [],
      "essential" : true,
      "environment" : [
        { "name" : "DATABASE_URL", "value" : "postgresql://postgres:marwan12@terraform-20230722105330038500000001.cgvxclvmavlm.eu-central-1.rds.amazonaws.com:5432/to_do_app?schema=public" }
      ],
      "portMappings" : [
        {
          "containerPort" : var.container_port,
          "hostPort" : var.host_port
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${var.cloudwatch_group}",
          "awslogs-region" : "eu-central-1",
          "awslogs-stream-prefix" : "ecs"
        }
      }
      "cpu" : 256,
      "memory" : 512,
      "networkMode" : "awsvpc"
    }
  ])
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

# Defining the services that will actaully run to hold the application
resource "aws_ecs_service" "aws-ecs-service" {
  name                 = var.app_name
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  desired_count        = 1
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  force_new_deployment = true

  network_configuration {
    subnets          = var.subnets
    assign_public_ip = false
    security_groups = [
      var.service_security_group_id,
    ]
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = var.app_name
    container_port   = var.container_port
  }
}
