output "dns_name" {
  value = aws_instance.neo4j_instance.private_dns
}
