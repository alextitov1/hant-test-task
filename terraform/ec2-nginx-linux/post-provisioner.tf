# install and configure a simple app into the EC2 instance using Ansible


resource "null_resource" "ansible_provisioner" {
  depends_on = [module.ec2_nginx_linux]

  triggers = {
    instance_id = module.ec2_nginx_linux.instance_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for instance to be ready..."
      sleep 30
      
      export ANSIBLE_HOST_KEY_CHECKING=False

      ansible-playbook \
        -i "${module.ec2_nginx_linux.public_ip}," \
        -u ec2-user \
        --private-key="${path.module}/${local.name}-key.pem" \
        -e secret_name="${local.certificate_name}" \
        ../../ansible/cert-install.yaml

      ansible-playbook \
        -i "${module.ec2_nginx_linux.public_ip}," \
        -u ec2-user \
        --private-key="${path.module}/${local.name}-key.pem" \
        ../../ansible/simple-app-install.yaml
    EOT
  }
}