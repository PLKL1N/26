resource "aws_security_group" "vpc_environment" {
  name        = "${var.project}-vpc-environment-sg"
  description = "Cloudshell VPC Environment - EKS Private endpoint access"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTP anyopen"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "HTTPS anyopen"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-vpc-environment-sg" }
}

resource "aws_security_group" "book_alb" {
  name        = "${var.project}-book-alb-sg"
  description = "wskorea26-book-alb - HTTP 80 inbound anyopen"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP anyopen"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-book-alb-sg" }
}

resource "aws_security_group" "grafana_alb" {
  name        = "${var.project}-grafana-alb-sg"
  description = "wskorea26-grafana-alb - HTTP 80 inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP anyopen"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-grafana-alb-sg" }
}

resource "aws_security_group" "node_extra" {
  name        = "${var.project}-node-extra-sg"
  description = "Allow NodePort traffic from ALBs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NodePort from book ALB"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.book_alb.id, aws_security_group.grafana_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-node-extra-sg" }
}
