/*
 * Public Subnet for Jenkins and Build Slaves
 */
resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_id
  map_public_ip_on_launch = true
  cidr_block              = var.public_subnet_cidr

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-public-subnet"
    Service   = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}


resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-public-route-table"
    Service   = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.public.id]

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-public-network-acl"
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
  user_data                   = data.template_file.setup_master.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    private_key = file(var.private_ssh_key)
    user        = "ubuntu"
    host        = aws_instance.jenkins_master.public_ip
  }

  # Copy in files needed to configure jenkins service (${path.module}/scripts/master/)
  provisioner "file" {
    content     = data.template_file.basic_security.rendered
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
    content     = data.template_file.install_state.rendered
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
    content     = data.template_file.nginx_conf.rendered
    destination = "/tmp/nginx.conf"
  }
  provisioner "file" {
    source      = var.ssl_cert_file
    destination = "/tmp/${var.ssl_cert_file}"
  }
  provisioner "file" {
    source      = var.ssl_cert_key
    destination = "/tmp/${var.ssl_cert_key}"
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
