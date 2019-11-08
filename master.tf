/*
 * Define Jenkins master instance
 */
resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.jenkins_master.id
  instance_type          = var.master_instance_type
  key_name               = var.ssh_key_pair
  vpc_security_group_ids = [aws_security_group.jenkins_master.id]
  subnet_id              = aws_subnet.default.id
  monitoring             = true
  availability_zone      = element(var.availability_zones, 0)

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-master"
    NameSpace = var.namespace
    Stage     = var.stage
  }

  volume_tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-master-volume"
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

/*
 * Create the security group that's applied to the Jenkins master instance
 */
resource "aws_security_group" "jenkins_master" {
  name   = "${var.namespace}-${var.stage}-${var.name}-master-sec-grp"
  vpc_id = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS from anywhere
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}
