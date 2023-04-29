resource "aws_security_group" "db-security_group" {
  name = "${var.environment}-${var.app_name}-db-sg"

  description = "Security group to allow access from ec2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ec2 instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.security_groups
  }
}

resource "aws_db_instance" "db-instance" {
  allocated_storage    = 10
  db_name              = "maro"
  engine               = "postgres"
  engine_version       = "10"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = var.db_subnet_group_name
  #   manage_master_user_password = true
  username = var.db_username
  password = var.db_password
  #   parameter_group_name = "default.mysql5.7"
}
