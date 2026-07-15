resource "aws_cloudwatch_log_group" "access" {
  name              = var.log_group_name
  retention_in_days = 7
  tags              = { Name = "${var.project}-book-svc-access" }
}

resource "aws_cloudwatch_log_stream" "az_a" {
  name           = "/book-svc/ap-northeast-2a"
  log_group_name = aws_cloudwatch_log_group.access.name
}

resource "aws_cloudwatch_log_stream" "az_b" {
  name           = "/book-svc/ap-northeast-2b"
  log_group_name = aws_cloudwatch_log_group.access.name
}
