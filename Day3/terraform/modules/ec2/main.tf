resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.keypair_name
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "this" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.cwd}/${var.keypair_name}.pem"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.latest_ami.value
  subnet_id                   = var.public_subnet_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = false
  iam_instance_profile = var.instance_profile_name
  user_data = templatefile("${path.module}/bastion.sh", { src_bucket = var.src_bucket })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = var.instance_name
  }
}

resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = {
    Name = "${var.instance_name}-eip"
  }

  depends_on = [aws_instance.bastion]
}
