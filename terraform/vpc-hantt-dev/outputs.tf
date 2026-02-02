output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs with their CIDR blocks and availability zones"
  value = [
    for subnet_id in module.vpc.public_subnets :
    {
      id                = subnet_id
      cidr              = data.aws_subnet.public[subnet_id].cidr_block
      availability_zone = data.aws_subnet.public[subnet_id].availability_zone
    }
  ]
}



