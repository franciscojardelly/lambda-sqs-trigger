# -----------------------------------------------------------------------------
# Base infrastructure
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project. Used as a prefix for all resource names."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Deployment environment. Must be one of: dev, staging, prod."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
  nullable    = false
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the Lambda function will be deployed."
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "List of private subnet IDs where the Lambda function will run."
  type        = list(string)
  nullable    = false
}

variable "ingress_rules" {
  description = "List of ingress rules for the Lambda security group."
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules for the Lambda security group. Defaults to allow all outbound traffic."
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# -----------------------------------------------------------------------------
# Integrations — outputs from other stacks
# -----------------------------------------------------------------------------

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue that will trigger the Lambda function. Sourced from the sqs-stack output this_sqs_queue_arn."
  type        = string
  nullable    = false
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket the Lambda function will read and write. Sourced from the s3-bucket-stack output this_s3_bucket_arn."
  type        = string
  nullable    = false
}

# -----------------------------------------------------------------------------
# Lambda configuration
# -----------------------------------------------------------------------------

variable "lambda_handler" {
  description = "Handler entry point for the Lambda function in the format file.function."
  type        = string
  default     = "handler.lambda_handler"
}

variable "lambda_timeout" {
  description = "Maximum execution time in seconds for the Lambda function (1–900)."
  type        = number
  default     = 60

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Amount of memory in MB allocated to the Lambda function (128–10240)."
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240 MB."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda CloudWatch logs."
  type        = number
  default     = 14
}

variable "app_log_level" {
  description = "Application log level passed to the Lambda via the LOG_LEVEL environment variable. Must be one of: DEBUG, INFO, WARN, ERROR."
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.app_log_level)
    error_message = "app_log_level must be one of: DEBUG, INFO, WARN, ERROR."
  }
}

variable "lambda_env_vars" {
  description = "Extra environment variables injected into the Lambda function. Merged with ENVIRONMENT and LOG_LEVEL — those two keys are reserved and will be overwritten if provided here."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# SQS trigger configuration
# -----------------------------------------------------------------------------

variable "batch_size" {
  description = "Maximum number of SQS messages to retrieve per Lambda invocation (1–10000)."
  type        = number
  default     = 10

  validation {
    condition     = var.batch_size >= 1 && var.batch_size <= 10000
    error_message = "batch_size must be between 1 and 10000."
  }
}

variable "maximum_batching_window_in_seconds" {
  description = "Maximum time in seconds Lambda waits to gather a full batch before invoking (0–300). Set to 0 to disable batching window."
  type        = number
  default     = 5

  validation {
    condition     = var.maximum_batching_window_in_seconds >= 0 && var.maximum_batching_window_in_seconds <= 300
    error_message = "maximum_batching_window_in_seconds must be between 0 and 300."
  }
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

variable "lambda_role_permissions_boundary" {
  description = "ARN of the IAM permissions boundary policy to attach to the Lambda execution role. Set to null or \"\" to omit."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Dynatrace
# -----------------------------------------------------------------------------

variable "dt_agent_arn" {
  description = "ARN of the Dynatrace Lambda layer version to attach to the function."
  type        = string
  nullable    = false
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to merge into all resources. Keys Project, Environment, ManagedBy, and Stack are always set by locals."
  type        = map(string)
  default     = {}
}
