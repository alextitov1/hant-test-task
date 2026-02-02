# Packer Nginx AMI Builder

Creates an Amazon Linux 2023 AMI with nginx configured for HTTPS using a self-signed certificate.

## Usage

Credentials setup (adjust path as necessary):
Make sure the running user has access to AWS default VPC
```sh
source ../.secrets.sh
```
Initialize Packer plugins:
```bash
/usr/bin/packer init linux-nginx-ami.pkr.hcl
```

Validate configuration:
```bash
/usr/bin/packer validate linux-nginx-ami.pkr.hcl
```

Build AMI:
```bash
/usr/bin/packer build linux-nginx-ami.pkr.hcl
```
---

