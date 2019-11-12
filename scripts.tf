data "template_file" "setup_master" {
  template = "${file("${path.module}/scripts/setup_master.sh")}"

  vars = {
    jenkins_version = var.jenkins_version
    ssl_cert_file   = var.ssl_cert_file
    ssl_cert_key    = var.ssl_cert_key
  }
}

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

data "template_file" "nginx_conf" {
  template = "${file("${path.module}/scripts/master/nginx.conf")}"

  vars = {
    domain_name   = var.domain_name
    ssl_cert_file = var.ssl_cert_file
    ssl_cert_key  = var.ssl_cert_key
  }
}
