output "vpc_id"   { value = aws_vpc.mgmt.id }
output "vpc_cidr" { value = aws_vpc.mgmt.cidr_block }

output "public_subnet_ids" { value = [aws_subnet.public.id] }

output "bastion_public_ip"   { value = aws_eip.bastion.public_ip }
output "bastion_private_ip"  { value = aws_instance.bastion.private_ip }
output "bastion_instance_id" { value = aws_instance.bastion.id }

output "bastion_private_key_pem" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}
