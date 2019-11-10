/*
 * Public Subnet for Jenkins and Build Slaves
 */
resource "aws_subnet" "public" {
  vpc_id     = var.vpc_id
  cidr_block = var.public_subnet_cidr

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-public-subnet"
    Service   = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

/*
 * Elastic IP for Jenkins master
 */
resource "aws_eip" "default" {
  instance = aws_instance.jenkins_master.id
  vpc      = true

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-eip"
    Service   = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

/*
 * Lookup up Ubuntu AMI for jenkins servers
 */
data "aws_ami" "ubuntu" {
  owners = ["099720109477"] # Canonical User (https://canonical.com/)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  most_recent = true
}

/*
 * Create Jenkins Master instance
 */
resource "aws_instance" "jenkins_master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  key_name                    = var.ssh_key_pair
  vpc_security_group_ids      = [aws_security_group.jenkins_master.id]
  subnet_id                   = aws_subnet.public.id
  monitoring                  = true
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = templatefile("${path.module}/scripts/setup_master.sh", { jenkins_version = var.jenkins_version })

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
  }

  # Copy in files needed to configure jenkins service (${path.module}/scripts/master/)
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/master/basic-security.groovy", { jenkins_username = var.jenkins_username, jenkins_password = var.jenkins_password })
    destination = "/tmp/basic-security.groovy"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/master/basic-security.groovy"
    destination = "/tmp/basic-security.groovy"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/master/disable-cli.groovy"
    destination = "/tmp/disable-cli.groovy"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/master/disable-jnlp.groovy"
    destination = "/tmp/disable-jnlp.groovy"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/master/install-plugins.sh"
    destination = "/tmp/install-plugins.sh"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/master/jenkins"
    destination = "/tmp/jenkins"
  }
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/master/jenkins.install.UpgradeWizard.state", { jenkins_version = var.jenkins_version })
    destination = "/tmp/jenkins.install.UpgradeWizard.state"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/master/node-agent.groovy"
    destination = "/tmp/node-agent.groovy"
  }
  provisioner "file" {
    source      = "${path.module}/scripts/master/plugins.txt"
    destination = "/tmp/plugins.txt"
  }



  provisioner "file" {
    content     = templatefile("${path.module}/scripts/master/jenkins.install.UpgradeWizard.state", { jenkins_version = var.jenkins_version })
    destination = "/tmp/jenkins.install.UpgradeWizard.state"
  }

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-master"
    Service   = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }

  volume_tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-master-root-volume"
    Service   = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

/*
 * Create Jenkins Master Decurity Group
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
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound ICMP (Ping) requests
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
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
    Name      = "${var.namespace}-${var.stage}-${var.name}-master-sec-grp"
    Service   = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}
