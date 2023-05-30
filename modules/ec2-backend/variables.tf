variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_id" {
  type = string
}

variable "alb_security_group" {
  type = string
}

variable "tg_arn" {
  type = string
}

variable "security_group_id" {
  type = string
}
