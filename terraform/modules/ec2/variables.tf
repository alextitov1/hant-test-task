variable "ec2" {
  type = object({
    name                        = string
    ami                         = optional(string, null)
    instance_type               = string
    key_name                    = optional(string, null)
    subnet_id                   = string
    create_eip                  = optional(bool, false)
    create_security_group       = optional(bool, true)
    security_group_ingress_rules = optional(map(object({
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  })), null)
    vpc_security_group_ids      = optional(list(string), [])
    create_iam_instance_profile = optional(bool, true)
    iam_role_description        = optional(string, "IAM role for EC2 instance")
    iam_role_policies           = optional(map(string), {})
    user_data                   = optional(string, null)
    tags                        = optional(map(string), {})
  })
  description = "Configuration for the EC2 instance"
}
