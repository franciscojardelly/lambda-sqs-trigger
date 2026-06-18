resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-sqs-processor"
  description = "Security group for the ${local.name_prefix} SQS processor Lambda function."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sqs-processor"
  })

  lifecycle {
    create_before_destroy = true
  }
}
