locals {
  name_prefix = "${var.project_name}-${var.environment}"

  has_pip_packages = length([
    for line in split("\n", file("${path.module}/src/requirements.txt"))
    : line if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]) > 0

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "lambda-sqs-stack"
  })
}
