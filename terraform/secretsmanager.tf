resource "aws_secretsmanager_secret" "magweb_creds_secret" {
  name        = "magweb-notifier-creds"
  description = "Credentials for magweb-notifier to access magweb website"
}

resource "aws_secretsmanager_secret_version" "magweb_creds_secret_version" {
  secret_id     = aws_secretsmanager_secret.magweb_creds_secret.id
  secret_string = jsonencode({
    username     = var.MAGWEB_USER
    password     = var.MAGWEB_PASSWORD
    twilio_token = var.TWILIO_TOKEN
  })
}
