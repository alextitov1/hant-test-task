locals {
  name   = "vpc-hantt-dev"
  region = "ap-southeast-6"


  vpc_cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Create /28 subnets for each availability zone (CIDR /16 + 12 bits)
  public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 12, k)]
  # TODO: Make additional subnet creation more convenient

  tags = {
    GithubRepo  = "hantt-dev-infra"
    GithubOrg   = "hantt-github-org"
    Environment = "dev"
  }
}