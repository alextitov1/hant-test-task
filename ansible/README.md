
# Intro

This directory contains Ansible playbooks for configuring nginx web server.

`nginx-playbook.yaml` - installs and configures nginx with HTTPS support. (it generates a temporary self-signed certificate). It's used in the Packer build to create an AMI with nginx pre-installed. (./packer/linux-nginx-ami.pkr.hcl)

`nginx-windows-playbook.yaml` - installs and configures nginx with HTTPS support on a Windows EC2 instance. It's used in the Packer build to create a Windows AMI with nginx pre-installed. (./packer/windows-nginx-ami.pkr.hcl)

`simple-app-install.yaml` - installs a sample web application(./extras/simple_app/), and configures EC2 instance to run this app behind nginx. This playbook used in the terraform post-provisioning step to configure the EC2 instance. (./terraform/ec2-nginx-linux/post-provisioner.tf)

`cert-install.yaml` - installs a SSL certificate from AWS Secrets Manager onto the EC2 instance and configures nginx to use this certificate. (./terraform/ec2-nginx-linux/post-provisioner.tf)


## Troubleshooting

```sh
# run playbook on linux ec2

ansible-playbook -i "3.103.147.242," -u ec2-user --private-key=../terraform/ec2-nginx-linux/nginx-linux-key.pem nginx-playbook.yaml
```

```sh
# run playbook on windows ec2

export ec2_ip=3.103.32.185
export ansible_password='admin pass'

ansible-playbook -i "$ec2_ip," -u Administrator --extra-vars "ansible_password='$ansible_password' ansible_connection=winrm ansible_winrm_scheme=http ansible_port=5985 ansible_winrm_server_cert_validation=ignore" nginx-windows-playbook.yaml
```
