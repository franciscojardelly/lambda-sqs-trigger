terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "lambda-sqs-stack/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
