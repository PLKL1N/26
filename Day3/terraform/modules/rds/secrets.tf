resource "aws_secretsmanager_secret" "rds" {
  name                    = "rds-secret"
  description             = "${var.project} RDS(${var.db_identifier}) connection info"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
