resource "aws_security_group" "neo4j_sg" {
  name   = "${var.prefix}-sg"
  vpc_id = var.vpc_id

  // allow neo4j browser traffic
  ingress {
    from_port       = 7474
    to_port         = 7474
    protocol        = "TCP"
    security_groups = var.source_security_groups
  }

  // allow neo4j bolt traffic
  ingress {
    from_port       = 7687
    to_port         = 7687
    protocol        = "TCP"
    security_groups = var.source_security_groups
  }

  // outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"      = "${var.prefix}-sg"
    "Terraform" = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
