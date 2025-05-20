# Outputs the access key ID (marked as sensitive)
output "access_key_id" {
  description = "The access key ID for the etluser IAM user"
  value       = aws_iam_access_key.etluser_key.id
  sensitive   = true
}

# Outputs the secret access key (marked as sensitive)
output "secret_access_key" {
  description = "The secret access key for the etluser IAM user"
  value       = aws_iam_access_key.etluser_key.secret
  sensitive   = true
} 