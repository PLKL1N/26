output "bastion_instance_id" {
  description = "Bastion EC2 Instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion Elastic IP (재시작 후에도 고정)"
  value       = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion Private IP"
  value       = aws_instance.bastion.private_ip
}

output "private_key_pem" {
  description = "Bastion SSH private key (Terraform provisioner 연결용)"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}
