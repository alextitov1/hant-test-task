locals {
  name = "nginx-linux"

  ami = "ami-01421266c0ec3966d" # build from packer/linux-nginx-ami.pkr.hcl

  instance_type = "t3.micro"
  
  key_name = aws_key_pair.ec2_key.key_name

  # custom variable - referencing the cert uploaded to Secrets Manager
  certificate_name = "hantt-service-cert-1SSKPM"

  # extracts VPC from subnet id
  subnet_id  = "subnet-0c793ef3cf90dea4e"
  create_eip = true

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for ${local.name} instance"
  iam_role_policies = {
    SecretAccess  = aws_iam_policy.secret_access.arn
    Ec2ReadAccess = aws_iam_policy.ec2_read_access.arn
  }

  # SG
  my_ip = "${chomp(data.http.my_public_ip.response_body)}/32"
  
  ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = local.my_ip
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = local.my_ip
    }
    ssh = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = local.my_ip
    }
  }

  tags = {
    GithubRepo  = "hantt-dev-infra"
    GithubOrg   = "hantt-github-org"
    Environment = "dev"
  }

}
