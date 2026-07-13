# =========================== DB Bootstrap (Bastion 경유) ===========================
# RDS가 private subnet에 있어 로컬 PC에서 직접 접근 불가.
# bastion에 SSH로 접속하여, bastion 내부에서 mysql 클라이언트로 RDS에 접속해 스키마(테이블 껍데기)를 생성한다.
# load_user.dump 적재는 대회 당일 bastion 접속 후 직접 수행 (EC2 -> RDS 접속하여 mysql 명령으로 적재).

resource "null_resource" "create_schema" {
  depends_on = [aws_db_instance.this]

  # rds 인스턴스가 재생성되면 스키마도 다시 적용
  triggers = {
    rds_endpoint = aws_db_instance.this.endpoint
  }

  connection {
    type        = "ssh"
    host        = var.bastion_public_ip
    user        = var.bastion_ssh_user
    private_key = var.bastion_private_key
    agent       = false
    timeout     = "3m"
  }

  provisioner "file" {
    source      = "${path.module}/sql/schema.sql"
    destination = "/tmp/schema.sql"
  }

  provisioner "remote-exec" {
    inline = [
      # AL2023 기본 mariadb-connector는 caching_sha2_password(MySQL8 기본 인증)를 지원하지 않아
      # MySQL 공식 client를 설치 (기존 mariadb 패키지와 파일 충돌 시 --allowerasing으로 정리)
      "sudo dnf -y install https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm",
      "sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023",
      "sudo dnf -y install mysql-community-client --allowerasing",
      "mysql -h ${aws_db_instance.this.address} -P ${aws_db_instance.this.port} -u ${var.db_username} -p'${random_password.master.result}' ${var.db_name} < /tmp/schema.sql",
    ]
  }
}
