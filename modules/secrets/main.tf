resource "aws_secretsmanager_secret" "secrets-manager" {
  name = "${var.environment}-${var.app_name}"
}

resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id     = aws_secretsmanager_secret.secrets-manager.id
  secret_string = var.secrets
}
