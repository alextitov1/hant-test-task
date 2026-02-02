data "aws_availability_zones" "available" {}

data "aws_subnet" "public" {
  for_each = toset(module.vpc.public_subnets)
  id       = each.value
}