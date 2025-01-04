module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "my-lambda1"
  description   = "My awesome lambda function"
  handler       = "function.lambda_handler"
  runtime       = "python3.11"

  source_path = "../src/notify"

  tags = {
    Name = "my-lambda1"
  }
}