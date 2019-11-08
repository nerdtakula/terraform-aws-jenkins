/*
 * This file contains steps to add the slave to jenkins as an agent
 */
data "template_file" "user_data_slave" {
  template = "${file("${path.module}/scripts/slave_join_cluster.sh.tpl")}"

  vars = {
    jenkins_url            = "http://${aws_instance.jenkins_master.private_ip}"
    jenkins_username       = var.jenkins_username
    jenkins_password       = var.jenkins_password
    jenkins_credentials_id = var.jenkins_credentials_id
  }
}

/*
 * Jenkins slaves launch configuration
 */
resource "aws_launch_configuration" "slaves" {
  name            = "${var.namespace}-${var.stage}-${var.name}-slave-launch-config"
  image_id        = data.aws_ami.jenkins_slave.id
  instance_type   = var.slave_instance_type
  key_name        = var.ssh_key_pair
  security_groups = [aws_security_group.jenkins_slaves.id]
  user_data       = data.template_file.user_data_slave.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*
 * Jenkins slaves Auto Scalling Group
 */
resource "aws_autoscaling_group" "jenkins_slaves" {
  name                      = "${var.namespace}-${var.stage}-${var.name}-slave-asg"
  launch_configuration      = aws_launch_configuration.slaves.name
  vpc_zone_identifier       = [aws_subnet.default.id]
  min_size                  = var.min_jenkins_slaves
  max_size                  = var.max_jenkins_slaves
  force_delete              = false
  health_check_grace_period = 300
  health_check_type         = "EC2"

  depends_on = ["aws_instance.jenkins_master", "aws_elb.jenkins_elb"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.namespace}-${var.stage}-${var.name}-slave"
    propagate_at_launch = true
  }

  tag {
    key                 = "NameSpace"
    value               = var.namespace
    propagate_at_launch = true
  }

  tag {
    key                 = "Stage"
    value               = var.stage
    propagate_at_launch = true
  }
}

/*
 * Create the security group that's applied to the Jenkins Slave instances
 */
resource "aws_security_group" "jenkins_slaves" {
  name   = "${var.namespace}-${var.stage}-${var.name}-slaves-sec-grp"
  vpc_id = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.jenkins_master.private_ip}/24"]
  }

  tags = {
    Name      = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

/*
 * Jenkins slaves scalling OUT
 */
resource "aws_cloudwatch_metric_alarm" "high-cpu-jenkins-slaves-alarm" {
  alarm_name          = "high-cpu-jenkins-slaves-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.jenkins_slaves.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale-out.arn}"]
}

resource "aws_autoscaling_policy" "scale-out" {
  name                   = "scale-out-jenkins-slaves"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.jenkins_slaves.name}"
}

/*
 * Jenkins slaves scalling IN
 */
resource "aws_cloudwatch_metric_alarm" "low-cpu-jenkins-slaves-alarm" {
  alarm_name          = "low-cpu-jenkins-slaves-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.jenkins_slaves.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale-in.arn}"]
}

resource "aws_autoscaling_policy" "scale-in" {
  name                   = "scale-in-jenkins-slaves"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.jenkins_slaves.name}"
}
