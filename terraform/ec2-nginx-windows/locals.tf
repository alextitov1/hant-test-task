locals {
  name = "nginx-windows"

  # ami = data.aws_ami.windows.id
  ami = "ami-0b687f5b3f1f1303c" # Created by Packer windows-nginx-ami.pkr.hcl

  instance_type = "m7i-flex.large"
  
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
    rdp = {
      from_port   = 3389
      to_port     = 3389
      ip_protocol = "tcp"
      cidr_ipv4   = local.my_ip
    }
    winrm = {
      from_port   = 5985
      to_port     = 5986
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
