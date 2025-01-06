resource "aws_sns_topic" "sms_notifications" {
  name = "sms-notifications-topic"
}

resource "aws_sns_topic_subscription" "phone_subscriptions" {
  for_each = toset(var.PHONE_NUMBERS) # List of phone numbers
  topic_arn = aws_sns_topic.sms_notifications.arn
  protocol  = "sms"
  endpoint  = each.key
}

resource "aws_iam_policy" "lambda_sns_policy" {
  name   = "LambdaSNSSendPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.sms_notifications.arn
      }
    ]
  })
}


