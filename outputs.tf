output "lb_dns_name" {
  value       = aws_elb.jenkins_elb.dns_name
  description = "Public DNS address of the Jenkins ELB"
}

output "jenkins_public_ip" {
  value       = aws_instance.jenkins_master.public_ip
  description = "Public IP address of the Jenkins ECS instance"
}
