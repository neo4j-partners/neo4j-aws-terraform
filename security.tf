resource "aws_security_group" "neo4j_sg" {
  name   = "${var.env_prefix}_sg"
  vpc_id = aws_vpc.neo4j_vpc.id

  // no restrictions on traffic originating from inside the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_base_cidr}"]
  }

  // no restrictions on traffic originating from the internet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
}