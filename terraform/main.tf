provider "aws" {
  region = "us-east-1"
}

# ✅ Key pair for SSH access
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${var.environment}"
  public_key = file("${path.module}/id_ed25519_personal.pub")
}

# ✅ Security group allowing HTTP, SSH, and ICMP
resource "aws_security_group" "web_access" {
  name        = "allow_http_icmp_ssh-${var.environment}"
  description = "Allow HTTP, ICMP, and SSH inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP (Ping)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ✅ EC2 instance pulling image from Docker Hub
resource "aws_instance" "web" {
  ami             = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.web_access.name]

  user_data = <<-EOF
              #!/bin/bash
              set -e
              echo "🚀 Starting EC2 user_data for ${var.environment}"
              
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # Wait for Docker to be ready
              sleep 10
              
              # Pull and run image from Docker Hub
              docker pull raohus/node-app:${var.environment}
              docker run -d -p 80:3000 raohus/node-app:${var.environment}
              
              echo "✅ Node app deployed successfully with Docker image: raohus/node-app:${var.environment}"
              EOF

  tags = {
    Name = "Terraform-EC2-${var.environment}"
  }
}

# ✅ Output EC2 public IP for Jenkins
output "ec2_public_ip" {
  description = "Public IP address of the deployed EC2 instance"
  value       = aws_instance.web.public_ip
}

