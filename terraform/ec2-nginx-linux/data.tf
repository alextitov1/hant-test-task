data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^al2023-ami-2023.*-x86_64"
}

data "aws_subnet" "this" {
  id = local.subnet_id
}

data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com"
}
