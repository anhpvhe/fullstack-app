resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("${path.module}/../key/key.pub")
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "app_server" {
  ami           = "ami-05e491ac3791032d1"  # Amazon Linux 2 AMI
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "AppServer"
  }

    user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install docker -y
        sudo systemctl start docker
        sudo systemctl enable docker
    EOF
}

resource "aws_ecr_repository" "backend" {
  name = "spring-boot-backend"
}

resource "aws_ecr_repository" "frontend" {
  name = "react-frontend"
}

resource "aws_ecr_repository" "database" {
  name = "mysql-database"
}
