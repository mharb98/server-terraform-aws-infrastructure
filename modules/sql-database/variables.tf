variable "environment" {
  type = string
}

variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "db_subnet_group_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}
