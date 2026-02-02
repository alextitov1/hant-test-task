# Manage SSH key pair for EC2 instance

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "${local.name}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = local.tags
}

resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/${local.name}-key.pem"
  file_permission = "0600"
}