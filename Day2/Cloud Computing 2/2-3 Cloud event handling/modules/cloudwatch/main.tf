data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "trail" {
  bucket        = "${var.project}-event-trail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = { Name = "${var.project}-event-trail" }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid     = "AWSCloudTrailAclCheck"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = [aws_s3_bucket.trail.arn]
  }

  statement {
    sid     = "AWSCloudTrailWrite"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket.json
}

resource "aws_cloudtrail" "event" {
  name                          = "${var.project}-event-trail"
  s3_bucket_name                = aws_s3_bucket.trail.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.trail]
  tags       = { Name = "${var.project}-event-trail" }
}

locals {
  rules = {
    sg = {
      rule_name = "${var.project}-sg-change-rule"
      event_pattern = jsonencode({
        source        = ["aws.ec2"]
        "detail-type" = ["AWS API Call via CloudTrail"]
        detail = {
          eventSource       = ["ec2.amazonaws.com"]
          eventName         = ["AuthorizeSecurityGroupIngress"]
          requestParameters = { groupId = [var.security_group_id] }
        }
      })
    }
    role = {
      rule_name = "${var.project}-role-change-rule"
      event_pattern = jsonencode({
        source        = ["aws.ec2"]
        "detail-type" = ["AWS API Call via CloudTrail"]
        detail = {
          eventSource = ["ec2.amazonaws.com"]
          eventName = [
            "ReplaceIamInstanceProfileAssociation",
            "AssociateIamInstanceProfile",
            "DisassociateIamInstanceProfile",
          ]
        }
      })
    }
    terminate = {
      rule_name = "${var.project}-ec2-terminate-rule"
      event_pattern = jsonencode({
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Instance State-change Notification"]
        detail = {
          "instance-id" = [var.instance_id]
          state         = ["shutting-down", "terminated"]
        }
      })
    }
    type = {
      rule_name = "${var.project}-ec2-type-change-rule"
      event_pattern = jsonencode({
        source        = ["aws.ec2"]
        "detail-type" = ["AWS API Call via CloudTrail"]
        detail = {
          eventSource       = ["ec2.amazonaws.com"]
          eventName         = ["ModifyInstanceAttribute"]
          requestParameters = { instanceId = [var.instance_id] }
        }
      })
    }
  }
}

resource "aws_cloudwatch_event_rule" "rule" {
  for_each = local.rules

  name          = each.value.rule_name
  description   = "Cloud Event Handling - ${each.value.rule_name}"
  event_pattern = each.value.event_pattern
  tags          = { Name = each.value.rule_name }
}

resource "aws_cloudwatch_event_target" "target" {
  for_each = local.rules

  rule = aws_cloudwatch_event_rule.rule[each.key].name
  arn  = var.function_arns[each.key]
}

resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = local.rules

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.function_names[each.key]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule[each.key].arn
}
