# Skipped entirely when requirements.txt has no installable packages (local.has_pip_packages = false).

resource "terraform_data" "pip_install" {
  count = local.has_pip_packages ? 1 : 0

  triggers_replace = filemd5("${path.module}/src/requirements.txt")

  provisioner "local-exec" {
    command = <<-EOT
      python3 -m pip install \
        -r "${path.module}/src/requirements.txt" \
        -t "${path.module}/src/layer/python" \
        --upgrade \
        --quiet
    EOT
  }
}

data "archive_file" "layer" {
  count = local.has_pip_packages ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/src/layer"
  output_path = "${path.module}/.build/layer.zip"

  depends_on = [terraform_data.pip_install]
}

resource "aws_lambda_layer_version" "dependencies" {
  count = local.has_pip_packages ? 1 : 0

  filename             = data.archive_file.layer[0].output_path
  layer_name           = "${local.name_prefix}-sqs-processor-dependencies"
  description          = "Python dependencies for ${local.name_prefix} SQS processor"
  compatible_runtimes  = ["python3.12"]
  source_code_hash     = data.archive_file.layer[0].output_base64sha256
}
