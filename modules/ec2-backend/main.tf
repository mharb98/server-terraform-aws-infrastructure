provider "aws" {
  region = "eu-central-1"
}

resource "aws_placement_group" "placement-group" {
  name         = "${var.environment}-${var.app_name}-placement-group"
  strategy     = "spread"
  spread_level = "rack"
}

resource "aws_launch_template" "launch_template" {
  name = "${var.environment}-${var.app_name}-launch-template"

  image_id = "ami-0b7fd829e7758b06d"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  user_data = filebase64("${path.module}/user-data.sh")

  tags = {
    Name = "production-${var.app_name}"
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.environment}-${var.app_name}-asg"
  max_size            = 3
  min_size            = 0
  desired_capacity    = 2
  force_delete        = true
  placement_group     = aws_placement_group.placement-group.id
  vpc_zone_identifier = var.subnet_ids

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
