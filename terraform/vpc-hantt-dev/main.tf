module "vpc" {
  source = "../modules/vpc"

  vpc = {
    name           = local.name
    cidr           = local.vpc_cidr
    azs            = local.azs
    public_subnets = local.public_subnets

    tags = local.tags
  }
}