resource "aws_iam_policy" "lambda_s3_policy" {
  name   = "magweb-notifier-lambda-s3-access-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          module.magweb_notifier_s3_bucket.s3_bucket_arn,
          "${module.magweb_notifier_s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_secrets_policy" {
  name   = "LambdaSecretsManagerPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.magweb_creds_secret.arn
      }
    ]
  })
}

