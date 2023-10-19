data "aws_secretsmanager_random_password" "this" {
  password_length = 16
}

resource "aws_secretsmanager_secret" "this" {
  name = "neo4j-creds"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = data.aws_secretsmanager_random_password.this.random_password
}
