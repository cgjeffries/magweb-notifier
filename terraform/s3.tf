module "magweb_notifier_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "magweb-notifier-bucket"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = module.magweb_notifier_s3_bucket.s3_bucket_id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = module.magweb_notifier_lambda.lambda_role_arn
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${module.magweb_notifier_s3_bucket.s3_bucket_arn}",
          "${module.magweb_notifier_s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}