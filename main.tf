
provider "aws" {
    region = var.reg
    secret_key = var.sec-key
    access_key = var.access-key
}

terraform {
  backend "s3" {
    bucket = "fayzan-terraform-state"
    key = "state"
    region = "us-west-2"
  }
}


resource "aws_launch_configuration" "lc_conf" {
  name_prefix   = "terraform-lc"
  image_id = "ami-00ee4df451840fa9d"
  instance_type = var.my_instance_type
  key_name = "aws-key"
}

resource "aws_autoscaling_group" "asg_conf" {
  name                 = "terraform-asg"
  launch_configuration = aws_launch_configuration.lc_conf.name
  availability_zones = ["us-west-2a"]
  min_size             = 2
  max_size             = 3
  health_check_grace_period = 100
  health_check_type = "EC2"
  force_delete = true
tag {
    key                 = "Name"
    value               = "custom-ec2-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "Auto scaling policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg_conf.name
  policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu_metic" {
  alarm_name          = "auto-scaling-policy"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_conf.name
  }

  actions_enabled = true
  alarm_actions     = [aws_autoscaling_policy.asg_policy.arn]
}