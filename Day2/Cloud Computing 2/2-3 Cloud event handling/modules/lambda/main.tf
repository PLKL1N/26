data "aws_partition" "current" {}

resource "aws_sns_topic" "alert" {
  name = "${var.project}-event-alert"
  tags = { Name = "${var.project}-event-alert" }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/lambda-function.py"
  output_path = "${path.module}/build/lambda.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project}-event-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = { Name = "${var.project}-event-lambda-role" }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_remediation" {
  statement {
    sid       = "SGRemediation"
    actions   = ["ec2:RevokeSecurityGroupIngress", "ec2:DescribeSecurityGroups"]
    resources = ["*"]
  }

  statement {
    sid = "RoleRemediation"
    actions = [
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:ReplaceIamInstanceProfileAssociation",
      "ec2:AssociateIamInstanceProfile",
      "ec2:DisassociateIamInstanceProfile",
    ]
    resources = ["*"]
  }

  statement {
    sid = "TypeRemediation"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:ModifyInstanceAttribute",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassEc2Role"
    actions   = ["iam:PassRole"]
    resources = [var.ec2_role_arn]
  }

  statement {
    sid       = "PublishAlert"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alert.arn]
  }
}

resource "aws_iam_role_policy" "lambda_remediation" {
  name   = "${var.project}-event-lambda-remediation"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_remediation.json
}

locals {
  functions = {
    sg = {
      function_name = "${var.project}-sg-remediation"
      handler       = "lambda-function.sg_remediation_handler"
      environment = {
        SNS_TOPIC_ARN     = aws_sns_topic.alert.arn
        SECURITY_GROUP_ID = var.security_group_id
      }
    }
    role = {
      function_name = "${var.project}-role-remediation"
      handler       = "lambda-function.role_remediation_handler"
      environment = {
        SNS_TOPIC_ARN = aws_sns_topic.alert.arn
        INSTANCE_ID   = var.instance_id
        ROLE_NAME     = var.ec2_role_name
      }
    }
    terminate = {
      function_name = "${var.project}-ec2-terminate-alert"
      handler       = "lambda-function.ec2_terminate_handler"
      environment = {
        SNS_TOPIC_ARN = aws_sns_topic.alert.arn
      }
    }
    type = {
      function_name = "${var.project}-ec2-type-remediation"
      handler       = "lambda-function.ec2_type_remediation_handler"
      environment = {
        SNS_TOPIC_ARN = aws_sns_topic.alert.arn
        INSTANCE_ID   = var.instance_id
        INSTANCE_TYPE = var.instance_type
      }
    }
  }
}

resource "aws_lambda_function" "fn" {
  for_each = local.functions

  function_name    = each.value.function_name
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = each.value.handler
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 60

  environment {
    variables = each.value.environment
  }

  depends_on = [
    aws_iam_role_policy.lambda_remediation,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = { Name = each.value.function_name }
}
