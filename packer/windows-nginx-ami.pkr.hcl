packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-6"
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "ami_name_prefix" {
  type    = string
  default = "windows-nginx"
}

data "amazon-ami" "windows" {
  filters = {
    name                = "Windows_Server-2019-English-Full-Base-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = var.aws_region
}

source "amazon-ebs" "windows" {
  ami_name      = "${var.ami_name_prefix}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.windows.id
  
  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_use_ssl  = false
  winrm_insecure = true
  winrm_timeout  = "5m"

  user_data_file = "./bootstrap_winrm.txt"

  tags = {
    Name        = "${var.ami_name_prefix}-{{timestamp}}"
    Environment = "development"
    Created_by  = "packer"
    OS          = "Windows Server 2019"
    Service     = "webserver"
  }
}

build {
  name = "windows-nginx-ami"
  sources = [
    "source.amazon-ebs.windows"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible/nginx-windows-playbook.yaml"
    user          = "Administrator"
    use_proxy     = false
    extra_arguments = [
      "--connection", "winrm",
      "--extra-vars", "ansible_winrm_server_cert_validation=ignore ansible_connection=winrm ansible_winrm_scheme=http ansible_port=5985"
    ]
  }

  post-processor "manifest" {
    output     = "manifest-windows.json"
    strip_path = true
  }
}
