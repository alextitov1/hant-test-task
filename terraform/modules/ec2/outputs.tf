output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = module.ec2_instance.private_ip
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

