# --------------------------- Secrets Manager ---------------------------
# EC2/EKS에서 DB 접속정보를 코드/매니페스트에 평문으로 안 박고 조회할 수 있게 저장.
# 키 이름은 RDS Proxy를 앞에 두지 않는 현재 구성 기준(host, port).
# 나중에 RDS Proxy를 붙이면 host 값만 프록시 엔드포인트로 바꿔주면 됨.

resource "aws_secretsmanager_secret" "rds" {
  name                    = "rds-secret"
  description             = "${var.project} RDS(${var.db_identifier}) connection info"
  recovery_window_in_days = 0 # 대회/테스트용: 삭제 시 즉시 제거 (운영이면 7 이상 권장)
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
