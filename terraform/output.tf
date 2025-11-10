output "ec2_public_ip" {
  description = "Public IP address of the deployed EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

