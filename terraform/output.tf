output "ec2_instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ecr_backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_database_repository_url" {
  value = aws_ecr_repository.database.repository_url
}
