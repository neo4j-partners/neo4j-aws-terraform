module "neo4j" {
  source = "../"

  ami                    = "ami-012161ead0c35965d"
  env_prefix             = "test"
  vpc_id                 = "vpc-073f70dc070e3af8a"
  subnet                 = "subnet-017b5c86dcfd44a4f"
  password_secret_name   = "neo4j-password-test"
  volume_size            = 32
  target_region          = "eu-west-1"
  source_security_groups = ["sg-0d241eccdda62f95d"]
}
