project_name = "my-project"
environment  = "dev"
aws_region   = "us-east-1"

# Network — outputs da network-stack
vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"
subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]

ingress_rules = [
  # Lambda normalmente não precisa de ingress — adicione se houver necessidade
  # {
  #   description = "Allow internal VPC traffic"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
]

egress_rules = [
  {
    description = "HTTPS para APIs externas"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["192.168.10.0/24"]
  },
  {
    description = "PostgreSQL para o banco de dados"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
]

# SQS — output this_sqs_queue_arn from sqs-stack
sqs_queue_arn = "arn:aws:sqs:us-east-1:123456789012:my-project-dev-processor"

# S3 — output this_s3_bucket_arn from s3-bucket-stack
s3_bucket_arn = "arn:aws:s3:::my-project-dev-data"

# Lambda
lambda_timeout     = 60
lambda_memory_size = 128
log_retention_days = 7
app_log_level      = "DEBUG"

# SQS trigger
batch_size                         = 5
maximum_batching_window_in_seconds = 0

# Variáveis extras injetadas na Lambda — adicione quantas precisar
lambda_env_vars = {
  # Dynatrace OneAgent
  DT_TENANT                            = "xxxxxxxx"
  DT_CLUSTER_ID                        = "xxxxxxxx"
  DT_CONNECTION_BASE_URL               = "https://xxxxxxxx.live.dynatrace.com"
  DT_CONNECTION_AUTH_TOKEN             = "dt0c01.xxxx"
  DT_OPEN_TELEMETRY_ENABLE_INTEGRATION = "true"

  # Outras variáveis da aplicação
  # DB_HOST      = "my-project-dev.cluster.us-east-1.rds.amazonaws.com"
  # FEATURE_FLAG = "true"
}

# Dynatrace — ARN da layer
dt_agent_arn = "arn:aws:lambda:us-east-1:725887861453:layer:Dynatrace_OneAgent_1_latest:1"

# IAM — remova o comentário e preencha o ARN se o ambiente exigir permissions boundary
# lambda_role_permissions_boundary = "arn:aws:iam::123456789012:policy/permissions-boundary"

tags = {
  Owner      = "platform-team"
  Team       = "data-engineering"
  CostCenter = "engineering"
}
