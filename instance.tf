module "neo4j_password" {
  source = "github.com/cyscale/terraform-aws-secrets"

  secret_name = var.password_secret_name
}

locals {
  user_data = templatefile(
    "${path.module}/conf/user_data.sh",
    {
      ssm_cloudwatch_config = aws_ssm_parameter.cw_agent.name
      ssm_prometheus        = aws_ssm_parameter.prometheus.name
      neo4j_password        = module.neo4j_password.secret_string
      node_count            = 1
      neo4j_version         = "5"
      target_region         = var.target_region
      prefix                = var.prefix
    }
  )
}

resource "aws_ssm_parameter" "cw_agent" {
  description = "Cloudwatch agent config to configure custom log"
  name        = "/cloudwatch-agent/config"
  type        = "String"
  value       = file("${path.module}/conf/cw_agent_config.json")
}

resource "aws_ssm_parameter" "prometheus" {
  description = "Prometheus scrape config for neo4j"
  name        = "/cloudwatch-agent/prometheus"
  type        = "String"
  value       = file("${path.module}/conf/prometheus.yml")
}

resource "aws_instance" "neo4j_instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet
  vpc_security_group_ids = [aws_security_group.neo4j_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.neo4j_instance_profile.name
  user_data              = local.user_data

  root_block_device {
    volume_size = var.volume_size
    encrypted   = true
    volume_type = "gp3"
  }

  tags = {
    "Name"      = "${var.prefix}-instance"
    "Terraform" = true
  }

  // only set to true when developing/debugging.
  user_data_replace_on_change = false

  // don't force-recreate instance if only user data changes
  lifecycle {
    ignore_changes = [user_data]
  }
}
