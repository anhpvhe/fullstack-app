provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "your-unique-bucket-name-anhpvhe17"
#   acl    = "private"
  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "Production"
  }
}