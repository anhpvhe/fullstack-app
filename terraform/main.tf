provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "your-unique-bucket-name-anhpvhe17"
    key            = "terraform/state"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "key"
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

resource "aws_instance" "app_instance" {
  ami           = "ami-08a0d1e16fc3f61ea" # Amazon Linux AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.allow_ssh_http.name]

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

#   provisioner "local-exec" {
#     command = "echo ${self.public_ip} > public_ip.txt"
#   }

#   provisioner "file" {
#     source      = "public_ip.txt"
#     destination = "/home/ec2-user/public_ip.txt"
#   }

# provisioner "remote-exec" {
#     inline = [
#       "sudo yum update -y",
#       "sudo yum install docker -y",
#       "sudo systemctl start docker",
#       "sudo systemctl enable docker",
#     #   "echo ${self.public_ip} > /tmp/ec2_instance_ip.txt" // Write public IP to a file
#     ]
#   }

  # connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = file("${path.module}/../key/key.pem")
  #     host        = self.public_ip
  #   }
}

resource "aws_ecr_repository" "backend_repository" {
  name = "react-frontend"
}

output "ec2_instance_public_ip" {
  value = aws_instance.app_instance.public_ip
}

output "ecr_frontend_repository_url" {
  value = aws_ecr_repository.backend_repository.repository_url
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}

