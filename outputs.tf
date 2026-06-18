output "this_lambda_function_arn" {
  description = "ARN of the Lambda processor function."
  value       = aws_lambda_function.this.arn
}

output "this_lambda_function_name" {
  description = "Name of the Lambda processor function."
  value       = aws_lambda_function.this.function_name
}

output "this_iam_role_arn" {
  description = "ARN of the IAM execution role attached to the Lambda function."
  value       = aws_iam_role.this.arn
}

output "this_log_group_name" {
  description = "Name of the CloudWatch Log Group that receives Lambda logs."
  value       = aws_cloudwatch_log_group.this.name
}

output "this_event_source_mapping_uuid" {
  description = "UUID of the SQS-to-Lambda event source mapping."
  value       = aws_lambda_event_source_mapping.this.uuid
}

output "this_security_group_id" {
  description = "ID of the security group attached to the Lambda function."
  value       = aws_security_group.this.id
}
