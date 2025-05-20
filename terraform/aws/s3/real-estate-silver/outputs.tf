output "bucket_name" {
  description = "S3 버킷 이름"
  value       = aws_s3_bucket.real_estate_silver.bucket
}

output "bucket_arn" {
  description = "S3 버킷 ARN"
  value       = aws_s3_bucket.real_estate_silver.arn
}

output "bucket_id" {
  description = "S3 버킷 리소스 ID"
  value       = aws_s3_bucket.real_estate_silver.id
}

output "bucket_region" {
  description = "S3 버킷이 생성된 리전"
  value       = aws_s3_bucket.real_estate_silver.region
}

# 버킷 주소 uri
output "bucket_uri" {
  description = "S3 버킷 주소 URI"
  value       = "s3://${aws_s3_bucket.real_estate_silver.bucket}"
}

