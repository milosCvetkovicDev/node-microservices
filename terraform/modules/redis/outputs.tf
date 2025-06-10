output "id" {
  description = "The ID of the ElastiCache Replication Group"
  value       = aws_elasticache_replication_group.this.id
}

output "arn" {
  description = "The ARN of the ElastiCache Replication Group"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "The address of the endpoint for the primary node in the replication group"
  value       = try(aws_elasticache_replication_group.this.primary_endpoint_address, null)
}

output "reader_endpoint_address" {
  description = "The address of the endpoint for the reader node in the replication group"
  value       = try(aws_elasticache_replication_group.this.reader_endpoint_address, null)
}

output "configuration_endpoint_address" {
  description = "The address of the configuration endpoint (cluster mode only)"
  value       = try(aws_elasticache_replication_group.this.configuration_endpoint_address, null)
}

output "port" {
  description = "The port number on which the cache accepts connections"
  value       = local.port
}

output "member_clusters" {
  description = "The identifiers of all the nodes that are part of this replication group"
  value       = aws_elasticache_replication_group.this.member_clusters
}

output "security_group_id" {
  description = "The security group ID of the ElastiCache cluster"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = aws_security_group.this.arn
}

output "parameter_group_id" {
  description = "The ElastiCache parameter group id"
  value       = try(aws_elasticache_parameter_group.this[0].id, null)
}

output "subnet_group_name" {
  description = "The cache subnet group name"
  value       = try(aws_elasticache_subnet_group.this[0].name, null)
}

output "subnet_group_id" {
  description = "The cache subnet group id"
  value       = try(aws_elasticache_subnet_group.this[0].id, null)
}

output "engine_version_actual" {
  description = "The actual engine version"
  value       = aws_elasticache_replication_group.this.engine_version_actual
}

output "cluster_enabled" {
  description = "Indicates if cluster mode is enabled"
  value       = aws_elasticache_replication_group.this.cluster_enabled
}

output "auth_token_enabled" {
  description = "Whether auth token is enabled"
  value       = var.transit_encryption_enabled
}

output "secret_arn" {
  description = "The ARN of the secret containing the auth token"
  value       = try(aws_secretsmanager_secret.auth_token[0].arn, null)
}

output "secret_name" {
  description = "The name of the secret containing the auth token"
  value       = try(aws_secretsmanager_secret.auth_token[0].name, null)
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created"
  value = {
    slow_log   = aws_cloudwatch_log_group.slow_log.name
    engine_log = aws_cloudwatch_log_group.engine_log.name
  }
} 