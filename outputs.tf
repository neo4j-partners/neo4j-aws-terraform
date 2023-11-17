output "neo4j_browser_url" {
  value = "http://${aws_instance.neo4j_instance.private_dns}:7474"
}

output "lb_dns_name" {
  value = aws_instance.neo4j_instance.private_dns
}
