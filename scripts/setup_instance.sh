#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive"

echo "Install common tools"
sudo dpkg --purge --force-depends ca-certificates-java
sudo apt-get install -y apt-transport-https ca-certificates-java ca-certificates curl software-properties-common unzip

echo "Install Java JDK 8"
sudo apt-get remove -y java
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

echo "Install git"
sudo apt-get install -y git

echo "Setup SSH key"
mkdir /var/lib/jenkins/.ssh
touch /var/lib/jenkins/.ssh/known_hosts
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh
## TODO: get private key to jenkins
# mv /tmp/id_rsa /var/lib/jenkins/.ssh/id_rsa
# chmod 600 /var/lib/jenkins/.ssh/id_rsa

echo "Configure Jenkins"
mkdir -p /var/lib/jenkins/init.groovy.d
## TODO: install init scripts for jenkins to configure teh service
# mv /tmp/basic-security.groovy /var/lib/jenkins/init.groovy.d/basic-security.groovy
# mv /tmp/disable-cli.groovy /var/lib/jenkins/init.groovy.d/disable-cli.groovy
# mv /tmp/csrf-protection.groovy /var/lib/jenkins/init.groovy.d/csrf-protection.groovy
# mv /tmp/disable-jnlp.groovy /var/lib/jenkins/init.groovy.d/disable-jnlp.groovy
# mv /tmp/jenkins.install.UpgradeWizard.state /var/lib/jenkins/jenkins.install.UpgradeWizard.state
# mv /tmp/node-agent.groovy /var/lib/jenkins/init.groovy.d/node-agent.groovy
# chown -R jenkins:jenkins /var/lib/jenkins/jenkins.install.UpgradeWizard.state
# mv /tmp/jenkins /etc/default/jenkins
# chmod +x /tmp/install-plugins.sh
# bash /tmp/install-plugins.sh

echo "Starting Jenkins"
service jenkins start

echo "Install Nginx"
sudo apt-get install nginx

echo "Configure Nginx"
## TODO: Copy in SSL certs and site config
service restart nginx

echo "Clean up"
sudo apt-get clean
