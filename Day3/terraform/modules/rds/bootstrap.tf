# =========================== DB Bootstrap (Bastion 경유) ===========================

resource "null_resource" "create_schema" {
  depends_on = [aws_db_instance.this]

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
      "sudo dnf -y install https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm",
      "sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023",
      "sudo dnf -y install mysql-community-client --allowerasing",
      "mysql -h ${aws_db_instance.this.address} -P ${aws_db_instance.this.port} -u ${var.db_username} -p'${random_password.master.result}' ${var.db_name} < /tmp/schema.sql",
    ]
  }
}
