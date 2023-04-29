output "secrets" {
  value = jsondecode(aws_secretsmanager_secret_version.secrets.secret_string)
}
