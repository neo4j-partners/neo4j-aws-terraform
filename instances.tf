module "aws-secrets" {
  source = "github.com/cyscale/terraform-aws-secrets"

  secret_name = var.password_secret_name
}


resource "aws_instance" "neo4j_instance" {
  count = var.node_count
  ami   = var.ami

  instance_type = var.instance_type

  subnet_id              = element(var.instance_subnets, count.index % 3)
  vpc_security_group_ids = ["${aws_security_group.neo4j_sg.id}"]
  iam_instance_profile   = aws_iam_instance_profile.neo4j_instance_profile.name
  depends_on             = [aws_lb.neo4j_lb]

  user_data = templatefile(
    "${path.module}/neo4j.tftpl",
    {
      install_gds    = var.install_gds
      install_bloom  = var.install_bloom
      gds_key        = var.gds_key
      bloom_key      = var.bloom_key
      neo4j_password = module.aws-secrets.secret_string
      node_count     = var.node_count
      lb_fqdn        = aws_lb.neo4j_lb.dns_name
      lb_arn         = aws_lb.neo4j_lb.arn
      neo4j_version  = var.neo4j_version
      target_region  = var.target_region
      env_prefix     = var.env_prefix
    }
  )

  root_block_device {
    volume_size = var.volume_size
    encrypted   = true
    volume_type = "gp3"
  }

  tags = {
    "Name"      = "${var.env_prefix}-instance"
    "Terraform" = true
  }

  // only set to true when developing/debugging.  tf default = false
  user_data_replace_on_change = false

  // don't force-recreate instance if only user data changes
  lifecycle {
    ignore_changes = [user_data]
  }
}
