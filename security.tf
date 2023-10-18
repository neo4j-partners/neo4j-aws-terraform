resource "aws_security_group" "neo4j_sg" {
  name   = "${var.env_prefix}-sg"
  vpc_id = var.vpc_id

  // allow SSH traffic from var.ssh_source_cidr
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${var.ssh_source_cidr}"]
  }

  // allow neo4j browser traffic from var.neo4j_source_cide
  ingress {
    from_port   = 7474
    to_port     = 7474
    protocol    = "TCP"
    cidr_blocks = ["${var.neo4j_source_cidr}"]
  }

  // allow neo4j bolt traffic from var.neo4j_source_cide
  ingress {
    from_port   = 7687
    to_port     = 7687
    protocol    = "TCP"
    cidr_blocks = ["${var.neo4j_source_cidr}"]
  }

  // outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"      = "${var.env_prefix}-sg"
    "Terraform" = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
