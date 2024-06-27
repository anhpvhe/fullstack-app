variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "key"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}
