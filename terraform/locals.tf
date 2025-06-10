locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "node-microservices"
    },
    var.tags
  )
  
  # Subnet calculations
  private_subnet_cidrs = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnet_cidrs  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i + 8)]
  database_subnet_cidrs = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i + 12)]
  
  # EKS configuration
  eks_cluster_name = "${local.name_prefix}-eks"
  
  # Database configuration
  db_name     = replace("${var.project_name}_${var.environment}", "-", "_")
  db_username = "microservices_admin"
  
  # Security groups
  eks_security_group_rules = {
    ingress_nodes_443 = {
      description = "Node groups to cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Allow all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
} 