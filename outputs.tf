output "ssh_commands" {
  value = [
    for key, value in aws_instance.neo4j_instance[*].public_ip : "ssh -o StrictHostKeyChecking=no -i ${var.private_key_path} ec2-user@${value}"
  ]
}

output "neo4j_browser_url" {
  value = "http://${aws_lb.neo4j_lb.dns_name}:7474"
}
