resource "aws_vpc" "mgmt" {
  cidr_block           = var.mgmt_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.project}-mgmt-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.mgmt.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-mgmt-public-subnet-a" }
}

resource "aws_internet_gateway" "mgmt" {
  vpc_id = aws_vpc.mgmt.id
  tags   = { Name = "${var.project}-mgmt-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mgmt.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mgmt.id
  }
  tags = { Name = "${var.project}-mgmt-public-rtb" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "bastion" {
  name        = "${var.project}-mgmt-bastion-sg"
  description = "Mgmt bastion"
  vpc_id      = aws_vpc.mgmt.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-mgmt-bastion-sg" }
}

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
  file_permission = "0400"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023.value
  subnet_id                   = aws_subnet.public.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  iam_instance_profile        = var.instance_profile_name
  user_data                   = file("${path.module}/bastion.sh")

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    tags                  = { Name = "${var.instance_name}-root-volume" }
  }
  tags = { Name = var.instance_name }
}

resource "aws_eip" "bastion" {
  domain     = "vpc"
  instance   = aws_instance.bastion.id
  tags       = { Name = "${var.instance_name}-eip" }
  depends_on = [aws_internet_gateway.mgmt]
}
