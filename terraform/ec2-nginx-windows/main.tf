module "ec2_nginx_windows" {
  source = "../modules/ec2"

  ec2 = {
    name                         = "ec2-${local.name}"
    ami                          = local.ami
    instance_type                = local.instance_type
    key_name                     = local.key_name
    subnet_id                    = local.subnet_id
    create_eip                   = local.create_eip
    create_security_group        = true
    security_group_ingress_rules = local.ingress_rules
    create_iam_instance_profile  = local.create_iam_instance_profile
    iam_role_description         = local.iam_role_description
    iam_role_policies            = local.iam_role_policies
    user_data                    = file("${path.module}/user_data.tftpl")
    tags                         = local.tags
  }
}

