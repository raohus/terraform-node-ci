#############################################
#  Terraform + AWS EC2 Node.js App Deployment
#############################################

provider "aws" {
  region = "us-east-1"
}

#############################################
#  Key Pair (for EC2 login, optional)
#############################################
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/id_ed25519_personal.pub")
}

#############################################
#  Security Group (Allow HTTP, SSH, ICMP)
#############################################
resource "aws_security_group" "web_access" {
  name        = "allow_http_icmp_ssh"
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

#############################################
#  EC2 Instance - Docker + Node.js App
#############################################
resource "aws_instance" "web" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  security_groups        = [aws_security_group.web_access.name]

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y

              # Install Docker
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Install Git
              yum install -y git

              # Clone your app repo
              cd /home/ec2-user
              git clone https://github.com/raohus/terraform-node-ci.git app

              # Build and run the app using Docker
              cd app
              docker build -t node-app .
              docker run -d -p 80:3000 node-app
              EOF

  tags = {
    Name = "Terraform-EC2-NodeApp"
  }
}

