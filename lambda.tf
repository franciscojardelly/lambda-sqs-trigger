# -----------------------------------------------------------------------------
# Package the Lambda source code
# -----------------------------------------------------------------------------

data "archive_file" "this" {
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/.build/handler.zip"
}

# -----------------------------------------------------------------------------
# Lambda function
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = "${local.name_prefix}-processor"
  description   = "Processes SQS messages and interacts with S3 for the ${var.project_name} project (${var.environment})."
  role          = aws_iam_role.this.arn

  filename      = data.archive_file.this.output_path
  code_sha256   = data.archive_file.this.output_base64sha256

  runtime     = "python3.12"
  handler     = var.lambda_handler
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size
  layers = concat(
    [var.dt_agent_arn],
    local.has_pip_packages ? [aws_lambda_layer_version.dependencies[0].arn] : []
  )

  environment {
    variables = merge(var.lambda_env_vars, {
      ENVIRONMENT             = var.environment
      LOG_LEVEL               = var.app_log_level
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/dynatrace"
    })
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.this.id]
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = var.app_log_level
    system_log_level      = "WARN"
    log_group             = aws_cloudwatch_log_group.this.name
  }

  tags = {
    Name = "${local.name_prefix}-processor"
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy.sqs_consumer,
    aws_iam_role_policy.s3_readwrite,
    aws_cloudwatch_log_group.this,
  ]
}

# -----------------------------------------------------------------------------
# SQS event source mapping — triggers the Lambda for each batch of messages
# -----------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn                   = var.sqs_queue_arn
  function_name                      = aws_lambda_function.this.arn
  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds
  enabled                            = true

  function_response_types = ["ReportBatchItemFailures"]
}
