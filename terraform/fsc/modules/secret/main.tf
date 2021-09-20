data "aws_secretsmanager_secret_version" "secret" {
  secret_id = var.secret_id
}
