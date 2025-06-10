output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = aws_db_instance.this.hosted_zone_id
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_instance_database_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = aws_security_group.this.id
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = try(aws_db_parameter_group.this[0].id, null)
}

output "db_subnet_group_id" {
  description = "The db subnet group id"
  value       = try(aws_db_subnet_group.this[0].id, null)
}

output "db_subnet_group_name" {
  description = "The db subnet group name"
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = aws_db_instance.this.availability_zone
}

output "db_instance_multi_az" {
  description = "If the RDS instance is multi AZ enabled"
  value       = aws_db_instance.this.multi_az
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.this.status
}

output "db_instance_storage_encrypted" {
  description = "Whether the DB instance is encrypted"
  value       = aws_db_instance.this.storage_encrypted
}

output "secret_arn" {
  description = "The ARN of the secret containing the database credentials"
  value       = try(aws_secretsmanager_secret.db_password[0].arn, null)
}

output "secret_name" {
  description = "The name of the secret containing the database credentials"
  value       = try(aws_secretsmanager_secret.db_password[0].name, null)
}

output "monitoring_role_arn" {
  description = "The ARN of the enhanced monitoring IAM role"
  value       = try(aws_iam_role.monitoring[0].arn, null)
} 