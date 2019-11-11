data "template_file" "basic_security" {
  template = "${file("${path.module}/scripts/master/basic-security.groovy")}"

  vars = {
    jenkins_username = var.jenkins_username
    jenkins_password = var.jenkins_password
  }
}

data "template_file" "install_state" {
  template = "${file("${path.module}/scripts/master/jenkins.install.UpgradeWizard.state")}"

  vars = {
    jenkins_version = var.jenkins_version
  }
}
