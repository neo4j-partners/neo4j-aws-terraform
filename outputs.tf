output "ssh_commands" {
  value = [
    for key, value in aws_instance.neo4j_instance[*].public_ip : "ssh -o StrictHostKeyChecking=no -i ${var.private_key_path} ec2-user@${value}"
  ]
}

output "neo4j_browser_url" {
  value = "http://${aws_lb.neo4j_lb.dns_name}:7474"
}

output "neo4j_password" {
  value = var.neo4j_password
}

output "instance_type" {
  value = var.instance_type
}

output "public_key_value" {
  value = var.public_key_value
}

output "private_key_path" {
  value = var.private_key_path
}

output "node_count" {
  value = var.node_count
}

output "vpc_base_cidr" {
  value = var.vpc_base_cidr
}

output "install_gds" {
  value = var.install_gds
}

output "install_bloom" {
  value = var.install_bloom
}

output "install_apoc" {
  value = var.install_apoc
}

output "env_prefix" {
  value = var.env_prefix
}

output "target_region" {
  value = var.target_region
}

output "gds_key" {
  value = var.gds_key
}

output "bloom_key" {
  value = var.bloom_key
}