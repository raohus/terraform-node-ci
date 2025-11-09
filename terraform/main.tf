provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${var.environment}"
  public_key = file("${path.module}/id_ed25519_personal.pub")
}

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

resource "aws_instance" "web" {
  ami             = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.web_access.name]

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y docker
  systemctl start docker
  systemctl enable docker

# Load Docker image from Jenkins artifact (adjust path if needed)
  docker load -i /home/ec2-user/node-app.tar

# Run container with environment variable passed from Terraform
  docker run -d -p 3000:3000 -e NODE_ENV=${var.environment} node-app:latest
  EOF

  tags = {
    Name = "Terraform-EC2-${var.environment}"
  }
}

