provider "aws" {
  region     = "eu-central-1"
  access_key = ""
  secret_key = ""
}

resource "aws_placement_group" "placement-group" {
  name         = "${var.environment}-${var.app_name}-placement-group"
  strategy     = "spread"
  spread_level = "rack"
}

resource "aws_security_group" "security-group" {
  name        = "${var.environment}-${var.app_name}-security-group"
  description = "Allow HTTP traffic from alb"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    security_groups = [var.alb_security_group]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_launch_template" "launch_template" {
  name = "${var.environment}-${var.app_name}-launch-template"

  image_id = "ami-0b7fd829e7758b06d"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.security-group.id]
  }

  user_data = filebase64("${path.module}/user-data.sh")
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.environment}-${var.app_name}-asg"
  max_size            = 3
  min_size            = 1
  desired_capacity    = 2
  force_delete        = true
  placement_group     = aws_placement_group.placement-group.id
  vpc_zone_identifier = var.subnet_ids

  # initial_lifecycle_hook {
  #   name                 = "lifcycle-hook"
  #   default_result       = "CONTINUE"
  #   heartbeat_timeout    = 2000
  #   lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  # }

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_attachment" "asg_lb_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = var.tg_arn
}
