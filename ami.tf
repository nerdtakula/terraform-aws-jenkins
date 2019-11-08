/*
 * Query AMI for Jenkins Master (LTS ideally)
 */
data "aws_ami" "jenkins_master" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["jenkins-2.190.2-*-linux-ubuntu-18.04-x86_64-hvm-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  most_recent = true
}

/*
 * Query AMI for Jenkins Slave
 */
data "aws_ami" "jenkins_slave" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["jenkins-slave-*-linux-ubuntu-18.04-x86_64-hvm-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  most_recent = true
}
