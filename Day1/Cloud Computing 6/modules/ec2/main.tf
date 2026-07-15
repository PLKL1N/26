resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.keypair_name
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "this" {
  content  = tls_private_key.this.private_key_pem
  filename = "${path.cwd}/${var.keypair_name}.pem"
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ssm_parameter.latest_ami.value
  subnet_id              = var.subnet_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [var.bastion_sg_id]
  iam_instance_profile   = var.instance_profile_name
  user_data              = file("${path.module}/bastion.sh")

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = { Name = "${var.instance_name}-root-volume" }
  }

  tags = { Name = var.instance_name }
}
