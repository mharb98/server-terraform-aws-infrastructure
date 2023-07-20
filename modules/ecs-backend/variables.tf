variable "repository_name" {
  description = "Name of the repository from which ecs will read the container"
  type        = string
}

variable "app_name" {
  description = "Name of the application for which the cluster is made"
  type        = string
}

variable "port" {
  description = "Port that will host the application"
  type        = number
}

variable "environment" {
  description = "Environment on which the application will be deployed e.g (testing/staging/production)"
  type        = string
}

variable "subnets" {
  description = "Subnets in the VPC that the ecs tasks will be built in"
  type        = list(string)
}

variable "alb_tg_arn" {
  description = "Target group for ecs backend that load balancer will point to"
  type        = string
}

variable "service_security_group_id" {
  description = "ID of the security group that will be attached to services in ecs cluster"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "IAM ecs task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "IAM role that will be attached to the services spin up by the task definition"
  type        = string
}
