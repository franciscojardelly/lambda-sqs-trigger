# -----------------------------------------------------------------------------
# Lambda execution role
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowLambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "${local.name_prefix}-lambda-processor"
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role.json
  permissions_boundary = nullif(var.lambda_role_permissions_boundary, "")

  tags = {
    Name = "${local.name_prefix}-lambda-processor"
  }
}

# -----------------------------------------------------------------------------
# Managed policy: basic Lambda execution (CloudWatch Logs)
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -----------------------------------------------------------------------------
# Inline policy: SQS — receive, delete, and inspect queue attributes
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "sqs_consumer" {
  statement {
    sid    = "AllowSQSConsume"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_role_policy" "sqs_consumer" {
  name   = "${local.name_prefix}-sqs-consumer"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.sqs_consumer.json
}

# -----------------------------------------------------------------------------
# Inline policy: S3 — read, write, and delete objects in the target bucket
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "s3_readwrite" {
  statement {
    sid    = "AllowS3GetObject"
    effect = "Allow"

    actions = ["s3:GetObject"]

    resources = ["${var.s3_bucket_arn}/*"]
  }

  statement {
    sid    = "AllowS3PutObject"
    effect = "Allow"

    actions = ["s3:PutObject"]

    resources = ["${var.s3_bucket_arn}/*"]
  }

  statement {
    sid    = "AllowS3DeleteObject"
    effect = "Allow"

    actions = ["s3:DeleteObject"]

    resources = ["${var.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_readwrite" {
  name   = "${local.name_prefix}-s3-readwrite"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.s3_readwrite.json
}
