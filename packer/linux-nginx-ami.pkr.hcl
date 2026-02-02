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
#################
### Variables ###
#################

variable "aws_region" {
  type    = string
  default = "ap-southeast-6"
}

variable "source_ami" {
  type    = string
  default = "" # Will be looked up using source_ami_filter
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "ami_name_prefix" {
  type    = string
  default = "nginx-https"
}

data "amazon-ami" "al2023" {
  filters = {
    name                = "al2023-ami-2023.*-x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = var.aws_region
}

#################
### Build  ######
#################

source "amazon-ebs" "nginx" {

  # If not specifying subnet, Packer will use default VPC for the region
  # subnet_id     = "subnet-0d809f3f305a92259"

  ami_name      = "${var.ami_name_prefix}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  
  source_ami    = var.source_ami != "" ? var.source_ami : data.amazon-ami.al2023.id
  ssh_username  = var.ssh_username

  tags = {
    Name        = "${var.ami_name_prefix}-{{timestamp}}"
    Environment = "development"
    Created_by  = "packer"
    OS          = "Amazon Linux 2023"
    Service     = "webserver"
  }
}

build {
  name = "nginx-https-ami"
  sources = [
    "source.amazon-ebs.nginx"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible/nginx-playbook.yaml"
    user          = var.ssh_username
    extra_arguments = [
      "--extra-vars",
      "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
