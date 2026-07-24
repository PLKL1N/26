output "endpoint" {
  description = "host:port 형태 엔드포인트"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "MYSQL_HOST 환경변수에 사용할 DNS 주소"
  value       = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "username" {
  value = aws_db_instance.this.username
}

output "password" {
  value     = var.db_password
  sensitive = true
}

output "security_group_id" {
  value = aws_security_group.rds.id
}

output "secret_arn" {
  value = aws_secretsmanager_secret.rds.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.rds.name
}
