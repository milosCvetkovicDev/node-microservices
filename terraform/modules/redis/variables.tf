variable "cluster_id" {
  description = "The cluster ID"
  type        = string
}

variable "description" {
  description = "Description for the cache cluster"
  type        = string
  default     = "Managed by Terraform"
}

# Engine Configuration
variable "engine_version" {
  description = "Version number of the cache engine"
  type        = string
  default     = "7.0"
}

variable "node_type" {
  description = "The instance class to be used"
  type        = string
  default     = "cache.t3.micro"
}

variable "family" {
  description = "The family of the ElastiCache parameter group"
  type        = string
  default     = "redis7"
}

# Cluster Configuration
variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) for this replication group (when cluster mode disabled)"
  type        = number
  default     = 1
}

variable "cluster_mode_enabled" {
  description = "Enable cluster mode (Redis Cluster Mode)"
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for this Redis replication group (when cluster mode enabled)"
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes in each node group (when cluster mode enabled)"
  type        = number
  default     = 1
}

variable "multi_az_enabled" {
  description = "Specifies whether to enable Multi-AZ Support for the replication group"
  type        = bool
  default     = false
}

variable "automatic_failover_enabled" {
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails"
  type        = bool
  default     = true
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of VPC Subnet IDs for the cache subnet group"
  type        = list(string)
}

variable "create_subnet_group" {
  description = "Whether to create a cache subnet group"
  type        = bool
  default     = true
}

variable "subnet_group_name" {
  description = "Name of the cache subnet group to be used for the replication group"
  type        = string
  default     = null
}

variable "allowed_security_groups" {
  description = "A list of Security Group IDs to allow access to"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "A list of CIDR blocks to allow access from"
  type        = list(string)
  default     = []
}

# Parameter Group
variable "create_parameter_group" {
  description = "Whether to create a parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Name of the parameter group to associate with this replication group"
  type        = string
  default     = null
}

variable "parameters" {
  description = "A list of Redis parameters to apply"
  type        = list(map(string))
  default     = []
}

# Security Configuration
variable "at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN of the key to use if encrypting at rest"
  type        = string
  default     = null
}

variable "transit_encryption_enabled" {
  description = "Whether to enable encryption in transit"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Password used to access a password protected server"
  type        = string
  default     = null
  sensitive   = true
}

variable "create_random_auth_token" {
  description = "Whether to create random auth token"
  type        = bool
  default     = true
}

variable "auth_token_length" {
  description = "Length of random auth token to create"
  type        = number
  default     = 32
}

variable "auth_token_update_strategy" {
  description = "Strategy to use when updating the auth_token"
  type        = string
  default     = "ROTATE"
}

variable "secret_recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret"
  type        = number
  default     = 7
}

# Backup Configuration
variable "snapshot_retention_limit" {
  description = "Number of days for which ElastiCache will retain automatic cache cluster snapshots"
  type        = number
  default     = 5
}

variable "snapshot_window" {
  description = "Daily time range during which ElastiCache will begin taking a daily snapshot"
  type        = string
  default     = "03:00-05:00"
}

variable "final_snapshot_identifier" {
  description = "The name of your final cluster snapshot"
  type        = string
  default     = null
}

# Maintenance Configuration
variable "maintenance_window" {
  description = "Specifies the weekly time range for when maintenance on the cache cluster is performed"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "auto_minor_version_upgrade" {
  description = "Specifies whether minor version engine upgrades will be applied automatically"
  type        = bool
  default     = true
}

variable "notification_topic_arn" {
  description = "ARN of an SNS topic to send ElastiCache notifications"
  type        = string
  default     = null
}

# Logging
variable "log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

# Other Configuration
variable "apply_immediately" {
  description = "Specifies whether any modifications are applied immediately"
  type        = bool
  default     = false
}

variable "data_tiering_enabled" {
  description = "Enables data tiering. Data tiering is only supported for replication groups using the r6gd node type"
  type        = bool
  default     = false
}

# CloudWatch Alarms
variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold for alarm"
  type        = number
  default     = 75
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold for alarm"
  type        = number
  default     = 75
}

variable "alarm_evictions_threshold" {
  description = "Evictions threshold for alarm"
  type        = number
  default     = 10
}

variable "alarm_actions" {
  description = "List of actions to execute when this alarm transitions into an ALARM state"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 