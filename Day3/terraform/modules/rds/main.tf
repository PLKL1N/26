resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-rds-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.project}-rds-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Allow MySQL access from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-rds-sg"
  }
}

resource "aws_db_parameter_group" "mysql80" {
  name        = "${var.project}-mysql80-params"
  family      = "mysql8.0"
  description = "apdev custom - raise max_connections"

  parameter {
    name         = "max_connections"
    value        = "180"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "wait_timeout"
    value        = "300"
    apply_method = "immediate"
  }

  parameter {
    name         = "interactive_timeout"
    value        = "300"
    apply_method = "immediate"
  }  

  parameter {
    name         = "sort_buffer_size"
    value        = "262144"
    apply_method = "immediate"
  }

  parameter {
    name         = "join_buffer_size"
    value        = "262144"
    apply_method = "immediate"
  }

  parameter {
    name         = "max_execution_time"
    value        = "3000"        # 밀리초 단위 = 3초
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier     = var.db_identifier
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.mysql80.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = var.db_identifier
  }
}
