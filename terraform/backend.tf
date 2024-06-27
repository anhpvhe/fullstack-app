terraform {
   backend "s3" {
    bucket         = "your-unique-bucket-name-anhpvhe17"
    key            = "terraform/state"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
