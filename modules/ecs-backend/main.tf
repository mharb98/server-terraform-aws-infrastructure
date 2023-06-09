provider "aws" {
  region = "eu-central-1"
}

# The repository from which the ecs services will pull the image
resource "aws_ecr_repository" "repository" {
  name = "ecs-${var.environment}-${var.app_name}"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# The cluster that will hold the task definitions and services
resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-${var.environment}-cluster"
  tags = {
    Name        = "${var.app_name}-ecs"
    Environment = var.environment
  }
}

# The template from which the services will be created
resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-task"

  container_definitions = jsonencode([
    {
      "name" : "${var.app_name}-${var.environment}-container",
      "image" : "nginx:latest",
      "entryPoint" : [],
      #   "environment": ${data.template_file.env_vars.rendered},
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ],
      "cpu" : 256,
      "memory" : 512,
      "networkMode" : "awsvpc"
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  # execution_role_arn       = var.ecs_task_execution_role_arn
  # task_role_arn            = var.ecs_task_execution_role_arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.environment
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

# Defining the services that will actaully run to hold the application
resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-${var.environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
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
    container_name   = "${var.app_name}-${var.environment}-container"
    container_port   = 80
  }
}
