module "neo4j" {
  source = "../"

  ami                  = "ami-012161ead0c35965d"
  env_prefix           = "test"
  vpc_id               = "vpc-073f70dc070e3af8a"
  subnet               = "subnet-028c7333e002657f7"
  password_secret_name = "neo4j-password-test"
  volume_size          = 32
  target_region        = "eu-west-1"
  source_sg            = "sg-0d241eccdda62f95d"
}
