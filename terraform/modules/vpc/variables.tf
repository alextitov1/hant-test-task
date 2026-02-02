variable "vpc" {
  type = object({
    name           = string
    cidr           = string
    azs            = list(string)
    public_subnets = list(string)

    tags = map(string)
  })
  description = "Configuration for the VPC"
}
