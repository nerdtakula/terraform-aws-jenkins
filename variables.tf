variable "region" {
  type        = string
  description = "AWS region in which to provision the AWS resources"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones for EFS"
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = string
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "description" {
  type        = string
  default     = "Jenkins EC2 instance"
  description = "Will be used as Elastic Beanstalk application description"
}

variable "master_instance_type" {
  type        = string
  default     = "t2.medium"
  description = "EC2 instance type for Jenkins master, e.g. 't2.medium'"
}

variable "slave_instance_type" {
  type        = string
  default     = "t2.medium"
  description = "EC2 instance type for Jenkins Slave, e.g. 't2.medium'"
}

variable "healthcheck_url" {
  type        = string
  description = "Application Health Check URL. Elastic Beanstalk will call this URL to check the health of the application running on EC2 instances"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to provision the AWS resources"
}

variable "igw_id" {
  type        = string
  description = "The ID of the Internet Gateway"
}

variable "cidr_block" {
  type        = string
  description = "CIDR Block of subnet and VPC"
}

variable "ssh_key_pair" {
  type        = string
  default     = ""
  description = "Name of SSH key that will be deployed on Elastic Compute Cloud instances. The key should be present in AWS"
}

variable "jenkins_username" {
  type        = string
  description = "Username for Jenkins Admin"
}

variable "jenkins_password" {
  type        = string
  description = "Password of Jenkins Admin"
}

variable "jenkins_credentials_id" {
  type        = string
  default     = "jenkins_ec2_slave_key"
  description = "Jenkins Slave Credentials ID"
}

variable "min_jenkins_slaves" {
  type        = string
  default     = 1
  description = "Minimum number of jenkins slaves to start"
}

variable "max_jenkins_slaves" {
  type        = string
  default     = 4
  description = "Max number of jenkins slaves that can be started"
}
