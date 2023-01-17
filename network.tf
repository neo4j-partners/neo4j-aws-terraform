resource "aws_vpc" "neo4j_vpc" {
  cidr_block           = var.vpc_base_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name"      = "${var.env_prefix}-vpc"
    "Terraform" = true
  }
}

resource "aws_subnet" "neo4j_public_subnet" {
  count = var.subnet_qty
  vpc_id                  = aws_vpc.neo4j_vpc.id
  cidr_block              = cidrsubnet(var.vpc_base_cidr, 8, count.index + 1)
  availability_zone       = join("", ["${var.target_region}", "${var.availability_zones[count.index]}"])
  map_public_ip_on_launch = true

  tags = {
    "Name"      = "${var.env_prefix}-public-subnet-${var.availability_zones[count.index]}"
    "Terraform" = true
  }
}

resource "aws_internet_gateway" "neo4j_igw" {
  vpc_id = aws_vpc.neo4j_vpc.id

  tags = {
    "Name"      = "${var.env_prefix}-vpc-igw"
    "Terraform" = true
  }
}

resource "aws_route_table" "neo4j_public_subnet_rt" {
  vpc_id = aws_vpc.neo4j_vpc.id
  tags = {
    "Name"      = "${var.env_prefix}-public-subnet-rt"
    "Terraform" = true
  }
}

resource "aws_route" "neo4j_public_subnet_route" {
  route_table_id         = aws_route_table.neo4j_public_subnet_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.neo4j_igw.id
}

resource "aws_route_table_association" "neo4j_public_route_assoc" {
  count          = var.subnet_qty
  subnet_id      = aws_subnet.neo4j_public_subnet[count.index].id
  route_table_id = aws_route_table.neo4j_public_subnet_rt.id
}
