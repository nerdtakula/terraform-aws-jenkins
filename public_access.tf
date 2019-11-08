/*
 * Create a subnet so that Slaves can talk to the master instance
 */
resource "aws_subnet" "default" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = element(var.availability_zones, 0)

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-subnet"
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

/*
 * Assign elastic IP to master instance
 */
resource "aws_eip" "jenkins_master" {
  instance = aws_instance.jenkins_master.id
  vpc      = true
}

/*
 * Load balancer in front of jenkins
 */
resource "aws_elb" "jenkins_elb" {
  name                        = "${var.namespace}-${var.stage}-${var.name}-elb"
  subnets                     = [aws_subnet.default.id]
  security_groups             = [aws_security_group.elb.id]
  instances                   = [aws_instance.jenkins_master.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  # availability_zones          = var.availability_zones

  # access_logs {
  #   bucket        = "elb-access-logs"
  #   bucket_prefix = "${var.namespace}-${var.stage}-${var.name}"
  #   interval      = 60
  # }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # listener {
  #   instance_port      = 8080
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = "arn:aws:acm:us-east-2:660079363290:certificate/ebd3a145-40d6-4e53-bef4-9b737db1e6ba"
  # }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = var.healthcheck_url
    interval            = 5
  }

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-elb"
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

resource "aws_security_group" "elb" {
  name        = "${var.namespace}-${var.stage}-${var.name}-elb-sec-grp"
  description = "Allow https traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-elb-sec-grp"
    NameSpace = var.namespace
    Stage     = var.stage
  }
}
