
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 6.2.0"
  # upstream module doc: https://github.com/terraform-aws-modules/terraform-aws-ec2-instance

  name = var.ec2.name

  ami = var.ec2.ami

  instance_type = var.ec2.instance_type
  key_name      = var.ec2.key_name
  subnet_id     = var.ec2.subnet_id
  create_eip    = var.ec2.create_eip
  
  vpc_security_group_ids = var.ec2.vpc_security_group_ids

  create_security_group        = var.ec2.create_security_group
  security_group_ingress_rules = var.ec2.security_group_ingress_rules

  create_iam_instance_profile = var.ec2.create_iam_instance_profile
  iam_role_description        = var.ec2.iam_role_description
  iam_role_policies           = var.ec2.iam_role_policies
  user_data                   = var.ec2.user_data

  tags = var.ec2.tags
}

