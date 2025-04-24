resource "aws_db_instance" "postgres-db" {
  apply_immediately     = false
  copy_tags_to_snapshot = true
  monitoring_interval   = 60
  publicly_accessible   = true
  skip_final_snapshot   = true
  allocated_storage     = 38
  max_allocated_storage = 1000
  engine                = "postgres"
  engine_version        = "15.5"
  instance_class        = "db.t3.micro"
  #   db_name              = local.name
  #   username             = "greta"
  parameter_group_name            = "default.postgres15"
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = ["postgresql"]
  description = "List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL)."
}
