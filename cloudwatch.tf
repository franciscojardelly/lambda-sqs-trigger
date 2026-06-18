# -----------------------------------------------------------------------------
# CloudWatch Log Group for the Lambda function
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.name_prefix}-processor"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "/aws/lambda/${local.name_prefix}-processor"
  }
}
