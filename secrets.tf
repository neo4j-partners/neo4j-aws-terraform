data "aws_secretsmanager_random_password" "this" {
  password_length     = 16
  exclude_punctuation = true
}

resource "aws_secretsmanager_secret" "this" {
  name = "neo4j-password"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = data.aws_secretsmanager_random_password.this.random_password

  lifecycle {
    ignore_changes = [secret_string]
  }
}
