output "vpc_id" {
  description = "ID of the application VPC"
  value       = aws_vpc.app_vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "deployment_type" {
  description = "Selected deployment scenario"
  value       = var.deployment_type
}

output "public_instance_id" {
  description = "Public EC2 instance ID"
  value       = try(aws_instance.public_app[0].id, null)
}

output "public_instance_ip" {
  description = "Public EC2 public IP"
  value       = try(aws_instance.public_app[0].public_ip, null)
}

output "ssm_instance_id" {
  description = "SSM EC2 instance ID"
  value       = try(aws_instance.ssm_app[0].id, null)
}

output "ssm_instance_private_ip" {
  description = "SSM EC2 private IP"
  value       = try(aws_instance.ssm_app[0].private_ip, null)
}

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = try(aws_instance.bastion[0].id, null)
}

output "bastion_public_ip" {
  description = "Bastion EC2 public IP"
  value       = try(aws_instance.bastion[0].public_ip, null)
}

output "bastion_private_app_instance_id" {
  description = "Private application EC2 instance ID"
  value       = try(aws_instance.bastion_private_app[0].id, null)
}

output "bastion_private_app_private_ip" {
  description = "Private application EC2 private IP"
  value       = try(aws_instance.bastion_private_app[0].private_ip, null)
}

output "nat_gateway_id" {
  description = "NAT Gateway ID, if enabled"
  value       = try(aws_nat_gateway.nat[0].id, null)
}