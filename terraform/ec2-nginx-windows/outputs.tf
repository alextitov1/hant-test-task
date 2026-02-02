output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2_nginx_windows.instance_id
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = module.ec2_nginx_windows.private_ip
}

output "instance_public_ip" {
  description = "The Elastic IP address of the EC2 instance"
  value       = module.ec2_nginx_windows.public_ip
}

output "vpc_id" {
  description = "The VPC ID where the instance is deployed"
  value       = data.aws_subnet.this.vpc_id
}

output "subnet_id" {
  description = "The subnet ID where the instance is deployed"
  value       = local.subnet_id
}

output "instance_name" {
  description = "The name of the EC2 instance"
  value       = local.name
}

output "https_url" {
  description = "HTTPS access URL (self-signed certificate)"
  value       = "https://${module.ec2_nginx_windows.public_ip}"
}

output "ami_id" {
  description = "The ID of the AMI used for EC2 instances"
  value       = local.ami
}
output "password_decryption_command" {
  description = "Command to decrypt the Windows Administrator password"
  value       = "aws ec2 get-password-data --instance-id ${module.ec2_nginx_windows.instance_id} --priv-launch-key ${local.name}-key.pem --region ap-southeast-6 --query PasswordData --no-cli-pager --output text"
}
