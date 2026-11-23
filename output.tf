output "vpc_id" {
  value = aws_vpc.DMZ-VPC.id
}

output "alb_dns_name" {
  description = "Open this in a brwoser to test"
  value       = aws_lb.this.dns_name
}

output "app_instance_ids" {
  description = "Use with: aws ssm start-session --target <id>"
  value       = aws_instance.app[*].id
}

output "nat_gateway_public_ips" {
  value = aws_eip.nat[*].public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.this.address
}