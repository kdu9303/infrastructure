output "glue_database_name" {
  description = "Glue Database 이름"
  value       = aws_glue_catalog_database.real_estate.name
}

output "glue_database_arn" {
  description = "Glue Database ARN"
  value       = aws_glue_catalog_database.real_estate.arn
}

output "glue_database_id" {
  description = "Glue Database 리소스 ID"
  value       = aws_glue_catalog_database.real_estate.id
}

# 아래는 Crawler, IAM Role 리소스가 활성화(주석 해제)될 경우 함께 출력할 수 있는 예시입니다.
output "glue_crawler_raw_name" {
  description = "Glue Crawler (raw) 이름"
  value       = aws_glue_crawler.real_estate_raw.name
}

output "glue_crawler_silver_name" {
  description = "Glue Crawler (silver) 이름"
  value       = aws_glue_crawler.real_estate_silver.name
}

output "glue_crawler_role_arn" {
  description = "Glue Crawler용 IAM Role ARN"
  value       = aws_iam_role.glue_crawler_role.arn
} 