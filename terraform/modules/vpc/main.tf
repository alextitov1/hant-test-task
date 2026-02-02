module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 6.6.0"
  # upstream module doc: https://github.com/terraform-aws-modules/terraform-aws-vpc

  name           = var.vpc.name
  cidr           = var.vpc.cidr
  azs            = var.vpc.azs
  public_subnets = var.vpc.public_subnets

  tags = var.vpc.tags
}