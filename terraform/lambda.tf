module "magweb_notifier_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "magweb-notifier-lambda"
  description   = "Notification lambda for magweb-notifier"
  handler       = "function.lambda_handler"
  runtime       = "python3.11"

  source_path = "../src/notify"

  attach_policies    = true
  number_of_policies = 2
  policies = [
    aws_iam_policy.lambda_s3_policy.arn,
    aws_iam_policy.lambda_secrets_policy.arn,
  ]

  environment_variables = {
    RUNNING_IN_AWS     = "True"
    MAGWEB_BUCKET_NAME = module.magweb_notifier_s3_bucket.s3_bucket_id
    MAGWEB_NAME        = var.MAGWEB_NAME
    MAGWEB_ID          = var.MAGWEB_ID
    TWILIO_SID         = var.TWILIO_SID
    PHONE_NUMBERS      = var.PHONE_NUMBERS
  }

  tags = {
    Name = "magweb-notifier-lambda"
  }
}

