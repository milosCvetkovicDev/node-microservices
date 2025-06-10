# Redis (ElastiCache) Module

locals {
  port = 6379
  
  subnet_group_name = var.create_subnet_group ? aws_elasticache_subnet_group.this[0].name : var.subnet_group_name
  
  auth_token = var.transit_encryption_enabled && var.create_random_auth_token ? random_password.auth_token[0].result : var.auth_token
}

# Random auth token
resource "random_password" "auth_token" {
  count = var.transit_encryption_enabled && var.create_random_auth_token ? 1 : 0

  length  = var.auth_token_length
  special = true
}

# Store auth token in AWS Secrets Manager
resource "aws_secretsmanager_secret" "auth_token" {
  count = var.transit_encryption_enabled && var.create_random_auth_token ? 1 : 0

  name_prefix             = "${var.cluster_id}-redis-auth-"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "auth_token" {
  count = var.transit_encryption_enabled && var.create_random_auth_token ? 1 : 0

  secret_id = aws_secretsmanager_secret.auth_token[0].id
  secret_string = jsonencode({
    auth_token = local.auth_token
    endpoint   = var.cluster_mode_enabled ? aws_elasticache_replication_group.this[0].configuration_endpoint_address : aws_elasticache_replication_group.this[0].primary_endpoint_address
    port       = local.port
  })
}

# Security group for Redis
resource "aws_security_group" "this" {
  name_prefix = "${var.cluster_id}-redis-"
  description = "Security group for ${var.cluster_id} Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from allowed security groups"
    from_port       = local.port
    to_port         = local.port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  ingress {
    description = "Redis from allowed CIDR blocks"
    from_port   = local.port
    to_port     = local.port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_id}-redis-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Subnet Group
resource "aws_elasticache_subnet_group" "this" {
  count = var.create_subnet_group ? 1 : 0

  name        = "${var.cluster_id}-redis-subnet-group"
  description = "Redis subnet group for ${var.cluster_id}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_id}-redis-subnet-group"
    }
  )
}

# Parameter Group
resource "aws_elasticache_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${var.cluster_id}-redis-params"
  family      = var.family
  description = "Redis parameter group for ${var.cluster_id}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_id}-redis-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Redis Replication Group (Cluster)
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.cluster_id
  description          = var.description

  # Engine
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = local.port

  # Cluster Configuration
  num_cache_clusters         = var.cluster_mode_enabled ? null : var.num_cache_clusters
  num_node_groups            = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group    = var.cluster_mode_enabled ? var.replicas_per_node_group : null
  multi_az_enabled           = var.multi_az_enabled
  automatic_failover_enabled = var.automatic_failover_enabled

  # Network
  subnet_group_name  = local.subnet_group_name
  security_group_ids = [aws_security_group.this.id]

  # Parameter Group
  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : var.parameter_group_name

  # Security
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.at_rest_encryption_enabled ? var.kms_key_id : null
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.transit_encryption_enabled ? local.auth_token : null
  auth_token_update_strategy = var.auth_token_update_strategy

  # Backup
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  final_snapshot_identifier = var.final_snapshot_identifier

  # Maintenance
  maintenance_window          = var.maintenance_window
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  notification_topic_arn      = var.notification_topic_arn

  # Logs
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  # Other
  apply_immediately = var.apply_immediately
  data_tiering_enabled = var.data_tiering_enabled

  tags = merge(
    var.tags,
    {
      Name = var.cluster_id
    }
  )

  depends_on = [
    aws_elasticache_subnet_group.this,
    aws_elasticache_parameter_group.this,
  ]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "slow_log" {
  name              = "/aws/elasticache/${var.cluster_id}/slow-log"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_id}-slow-log"
    }
  )
}

resource "aws_cloudwatch_log_group" "engine_log" {
  name              = "/aws/elasticache/${var.cluster_id}/engine-log"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_id}-engine-log"
    }
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.cluster_id}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  alarm_description   = "This metric monitors Redis CPU utilization"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = var.cluster_mode_enabled ? null : aws_elasticache_replication_group.this.id
    ReplicationGroupId = var.cluster_mode_enabled ? aws_elasticache_replication_group.this.id : null
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.cluster_id}-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_memory_threshold
  alarm_description   = "This metric monitors Redis memory utilization"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = var.cluster_mode_enabled ? null : aws_elasticache_replication_group.this.id
    ReplicationGroupId = var.cluster_mode_enabled ? aws_elasticache_replication_group.this.id : null
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "evictions" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.cluster_id}-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_evictions_threshold
  alarm_description   = "This metric monitors Redis evictions"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = var.cluster_mode_enabled ? null : aws_elasticache_replication_group.this.id
    ReplicationGroupId = var.cluster_mode_enabled ? aws_elasticache_replication_group.this.id : null
  }

  tags = var.tags
} 