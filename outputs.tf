output "dns_name" {
  value = aws_instance.neo4j_instance.private_dns
}

output "instance_arn" {
  value = aws_instance.neo4j_instance.arn
}
