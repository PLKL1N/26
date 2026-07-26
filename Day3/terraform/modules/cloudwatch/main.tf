resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-dashboard"

  dashboard_body = templatefile("${path.module}/dashboard.json.tpl", {
    alb_id = var.alb_arn_suffix
  })
}