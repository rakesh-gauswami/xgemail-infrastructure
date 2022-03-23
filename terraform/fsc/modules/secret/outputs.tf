output "secret_string" {
  value     = data.aws_secretsmanager_secret_version.secret.secret_string
  sensitive = true
}

output "secret_binary" {
  value     = data.aws_secretsmanager_secret_version.secret.secret_binary
  sensitive = true
}
