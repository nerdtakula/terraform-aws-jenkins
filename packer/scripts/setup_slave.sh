#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive"

echo "Install common tools"
sudo dpkg --purge --force-depends ca-certificates-java
sudo apt-get install -y apt-transport-https ca-certificates ca-certificates-java curl software-properties-common

echo "Install Java JDK 8"
sudo apt-get remove -y java
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk
java -version

echo "Install Docker engine"
sudo apt-get remove docker docker-engine docker.io
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo usermod -aG docker ubuntu
sudo service docker start

echo "Install git"
sudo apt-get install -y git

echo "Setup jenkins user"
sudo useradd -m -s /bin/bash jenkins
