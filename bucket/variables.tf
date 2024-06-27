variable "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  default     = "your-unique-bucket-name-anhpvhe17"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  default     = "terraform-locks"
}