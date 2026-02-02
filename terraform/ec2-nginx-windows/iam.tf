resource "aws_iam_policy" "secret_access" {
  name        = "${local.name}-secret-access"
  description = "Allow access to specific Secrets Manager secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        # this is the web service ssl certificate and key stored in secrets manager (outside of the AMI)
        Resource = "arn:aws:secretsmanager:*:*:secret:${local.certificate_name}"
      }
    ]
  })
}

# Designed access for the "simple service" to read its own EC2 metadata
resource "aws_iam_policy" "ec2_read_access" {
  name        = "${local.name}-ec2-read-access"
  description = "Allow EC2 to describe its own tags and status"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}
