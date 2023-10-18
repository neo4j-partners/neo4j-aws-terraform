output "neo4j_browser_url" {
  value = "http://${aws_lb.neo4j_lb.dns_name}:7474"
}

output "lb_dns_name" {
  value = aws_lb.neo4j_lb.dns_name
}

output "neo4j_password" {
  value     = var.neo4j_password
  sensitive = true
}

output "target_region" {
  value = var.target_region
}
