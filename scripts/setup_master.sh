#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive"

echo "Install common tools"
sudo dpkg --purge --force-depends ca-certificates-java
sudo apt-get install -y apt-transport-https ca-certificates-java ca-certificates curl software-properties-common unzip

echo "Install Java JDK 8"
sudo apt-get remove -y java openjdk-9-jdk
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk
java -version

echo "Install Jenkins LTS release '${jenkins_version}'"
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo add-apt-repository universe
sudo apt-get install -y jenkins=${jenkins_version}
sudo service jenkins stop

echo "Install git"
sudo apt-get install -y git

echo "Setup SSH key"
sudo mkdir /var/lib/jenkins/.ssh
sudo touch /var/lib/jenkins/.ssh/known_hosts
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh
## TODO: get private key to jenkins
# sudo mv /tmp/id_rsa /var/lib/jenkins/.ssh/id_rsa
# sudo chmod 600 /var/lib/jenkins/.ssh/id_rsa

echo "Configure Jenkins"
# sudo mkdir -p /var/lib/jenkins/init.groovy.d
# sudo mv /tmp/basic-security.groovy /var/lib/jenkins/init.groovy.d/basic-security.groovy
# sudo mv /tmp/disable-cli.groovy /var/lib/jenkins/init.groovy.d/disable-cli.groovy
# sudo mv /tmp/csrf-protection.groovy /var/lib/jenkins/init.groovy.d/csrf-protection.groovy
# sudo mv /tmp/disable-jnlp.groovy /var/lib/jenkins/init.groovy.d/disable-jnlp.groovy
# sudo mv /tmp/jenkins.install.UpgradeWizard.state /var/lib/jenkins/jenkins.install.UpgradeWizard.state
# sudo mv /tmp/node-agent.groovy /var/lib/jenkins/init.groovy.d/node-agent.groovy
# sudo chown -R jenkins:jenkins /var/lib/jenkins/jenkins.install.UpgradeWizard.state /var/lib/jenkins/init.groovy.d/
sudo mv /tmp/jenkins /etc/default/jenkins
sudo chmod +x /tmp/install-plugins.sh
sudo bash /tmp/install-plugins.sh

echo "Starting Jenkins"
sudo service jenkins start

echo "Install Nginx"
sudo apt-get install -y nginx

echo "Configure Nginx"
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.prev
sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf
sudo mkdir -p /etc/nginx/external
sudo mv /tmp/${ssl_cert_file} /etc/nginx/external
sudo mv /tmp/${ssl_cert_key} /etc/nginx/external
sudo service nginx restart

echo "Clean up"
sudo apt-get clean
