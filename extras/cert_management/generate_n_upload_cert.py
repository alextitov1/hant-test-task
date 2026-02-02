#!/usr/bin/env python3.12
"""
Generate a self-signed certificate and upload it to AWS Secrets Manager.
Usage: python upload_cert.py <service-name>
"""

import sys
import subprocess
import tempfile
import os
import boto3
# from pathlib import Path


def generate_self_signed_cert(service_name, output_dir):
    """Generate self-signed certificate using OpenSSL."""
    cert_file = os.path.join(output_dir, f"{service_name}.crt")
    key_file = os.path.join(output_dir, f"{service_name}.key")
    
    # Generate private key and certificate
    cmd = [
        "openssl", "req", "-x509", "-newkey", "rsa:2048",
        "-keyout", key_file,
        "-out", cert_file,
        "-days", "365",
        "-nodes",
        "-subj", f"/C=US/ST=State/L=City/O=Organization/CN={service_name}.example.com"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Error generating certificate: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    
    print(f"✓ Generated certificate: {cert_file}")
    print(f"✓ Generated private key: {key_file}")
    
    return cert_file, key_file


def upload_to_secrets_manager(service_name, cert_file, key_file):
    """Upload certificate to AWS Secrets Manager."""
    
    # Read certificate and key
    with open(cert_file, 'r') as f:
        certificate_body = f.read()
    
    with open(key_file, 'r') as f:
        private_key = f.read()
    
    # Initialize Secrets Manager client
    secrets_client = boto3.client('secretsmanager')
    
    try:
        # Import certificate to ACM
        response = secrets_client.create_secret(
            Name=f"{service_name}-cert",
            SecretString=f"{{\"certificate\": \"{certificate_body}\", \"private_key\": \"{private_key}\"}}",
            Tags=[
                {
                    'Key': 'Name',
                    'Value': f"{service_name}-cert"
                },
                {
                    'Key': 'Service',
                    'Value': service_name
                },
                {
                    'Key': 'ManagedBy',
                    'Value': 'upload_cert.py'
                }
            ]
        )
        
        secret_arn = response['ARN']
        print(f"✓ Certificate uploaded to Secrets Manager")
        print(f"  ARN: {secret_arn}")
        
        return secret_arn
        
    except Exception as e:
        print(f"Error uploading to Secrets Manager: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) != 2:
        print("Usage: python upload_cert.py <service-name>", file=sys.stderr)
        sys.exit(1)
    
    service_name = sys.argv[1]
    
    # Validate service name (basic alphanumeric + hyphens)
    if not all(c.isalnum() or c == '-' for c in service_name):
        print("Error: Service name must contain only alphanumeric characters and hyphens", file=sys.stderr)
        sys.exit(1)
    
    print(f"Generating self-signed certificate for service: {service_name}")
    
    # Create temporary directory for certificate files
    with tempfile.TemporaryDirectory() as tmpdir:
        # Generate certificate
        cert_file, key_file = generate_self_signed_cert(service_name, tmpdir)
        
        # Upload to Secrets Manager
        secret_arn = upload_to_secrets_manager(service_name, cert_file, key_file)
        
        print(f"\n✓ Successfully uploaded certificate for {service_name}")
        print(f"  Secret ARN: {secret_arn}")
        print(f"  Certificate will be automatically deleted from local filesystem")


if __name__ == "__main__":
    main()