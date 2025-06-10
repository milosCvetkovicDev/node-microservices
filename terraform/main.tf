# ====================================================================
# Terraform Configuration for Node.js Microservices Infrastructure
# ====================================================================
# This configuration provisions the complete cloud infrastructure for
# the microservices application including:
# - VPC with public/private/database subnets
# - EKS cluster for running microservices
# - RDS PostgreSQL for persistent data
# - ElastiCache Redis for caching and sessions
# - Essential Kubernetes add-ons
#
# Usage:
#   terraform init -backend-config=backend-${env}.conf
#   terraform plan -var-file=environments/${env}.tfvars
#   terraform apply -var-file=environments/${env}.tfvars
#
# Required AWS Permissions:
# - VPC: Full access
# - EKS: Full access
# - RDS: Full access
# - ElastiCache: Full access
# - IAM: Create roles and policies
# - S3: Backend state storage
# ====================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  # Backend configuration for state management
  # Configure via backend-{env}.conf file:
  # bucket         = "terraform-state-bucket"
  # key            = "microservices/{env}/terraform.tfstate"
  # region         = "us-east-1"
  # encrypt        = true
  # dynamodb_table = "terraform-state-lock"
  backend "s3" {
    # Backend configuration will be provided via backend config file
  }
}

# ====================================================================
# Provider Configurations
# ====================================================================

# AWS Provider - Main cloud provider
provider "aws" {
  region = var.aws_region
  
  # Default tags applied to all resources
  default_tags {
    tags = local.common_tags
  }
}

# Kubernetes Provider - For K8s resource management
# Configured to use the EKS cluster created below
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  # Use AWS CLI to get auth token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Helm Provider - For deploying Helm charts
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# ====================================================================
# Core Infrastructure Modules
# ====================================================================

# VPC Module - Network foundation
# Creates a VPC with:
# - Public subnets: For load balancers and NAT gateways
# - Private subnets: For EKS worker nodes
# - Database subnets: For RDS instances (extra isolation)
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix           = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  private_subnet_cidrs  = local.private_subnet_cidrs
  public_subnet_cidrs   = local.public_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs
  
  environment            = var.environment
  cluster_name           = local.eks_cluster_name
  
  # Cost optimization for non-production environments
  single_nat_gateway     = var.environment == "development"  # Use 1 NAT gateway in dev
  one_nat_gateway_per_az = var.environment == "production"   # Use 1 per AZ in prod
  
  # Security and compliance features
  enable_flow_log        = var.environment == "production"   # VPC Flow Logs for prod
  enable_s3_endpoint     = true                              # S3 VPC endpoint for efficiency
  
  aws_region             = var.aws_region
  tags                   = local.common_tags
}

# EKS Module - Kubernetes cluster
# Provisions:
# - EKS control plane
# - Managed node groups
# - IAM roles and policies
# - Security groups
module "eks" {
  source = "./modules/eks"
  
  cluster_name         = local.eks_cluster_name
  cluster_version      = var.eks_cluster_version
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  
  # Node group configuration (defined in tfvars)
  node_groups          = var.node_groups
  
  # Additional security group rules
  cluster_security_group_rules = local.eks_security_group_rules
  
  # IAM authentication configuration
  aws_auth_roles = var.eks_auth_roles
  aws_auth_users = var.eks_auth_users
  
  tags = local.common_tags
}

# RDS PostgreSQL Module - Primary database
# Features:
# - Multi-AZ deployment in production
# - Automated backups
# - Performance insights
# - Encryption at rest
module "rds" {
  source = "./modules/rds"
  
  identifier = "${local.name_prefix}-postgres"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.rds_instance_class
  
  # Storage configuration
  allocated_storage     = var.rds_allocated_storage      # Initial storage
  max_allocated_storage = var.rds_max_allocated_storage  # Auto-scaling limit
  storage_encrypted     = true                           # Always encrypt
  
  # Database configuration
  database_name   = local.db_name
  master_username = local.db_username
  
  # Network configuration
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.database_subnet_ids
  allowed_security_groups = [module.eks.node_security_group_id]  # Allow EKS nodes
  
  # Production vs Development settings
  backup_retention_period = var.environment == "production" ? 30 : 7   # Days
  multi_az                = var.environment == "production"            # HA in prod
  deletion_protection     = var.environment == "production"            # Prevent accidental deletion
  
  # Monitoring
  performance_insights_enabled = var.environment == "production"
  monitoring_interval          = var.environment == "production" ? 60 : 0  # CloudWatch metrics
  
  tags = local.common_tags
}

# Redis Module - Caching and sessions
# Features:
# - Cluster mode disabled (for simplicity)
# - Multi-AZ replication in production
# - Encryption in transit (production)
# - Automatic failover
module "redis" {
  source = "./modules/redis"
  
  cluster_id = "${local.name_prefix}-redis"
  
  engine_version = "7.0"
  node_type      = var.redis_node_type
  
  # High availability configuration
  num_cache_clusters         = var.environment == "production" ? 2 : 1
  automatic_failover_enabled = var.environment == "production"
  multi_az_enabled           = var.environment == "production"
  
  # Network configuration
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  allowed_security_groups = [module.eks.node_security_group_id]
  
  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = var.environment == "production"  # TLS in prod
  
  # Backup
  snapshot_retention_limit = var.environment == "production" ? 5 : 1
  
  tags = local.common_tags
}

# ====================================================================
# Kubernetes Add-ons
# ====================================================================

# Cluster Autoscaler - Automatically scales node groups
# based on pod resource requests
module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"
  count  = var.enable_cluster_autoscaler ? 1 : 0
  
  cluster_name      = module.eks.cluster_name
  cluster_oidc_arn  = module.eks.oidc_provider_arn
  namespace         = "kube-system"
  
  tags = local.common_tags
}

# Metrics Server - Required for HPA and resource monitoring
module "metrics_server" {
  source = "./modules/metrics-server"
  count  = var.enable_metrics_server ? 1 : 0
  
  namespace = "kube-system"
  
  depends_on = [module.eks]
}

# NGINX Ingress Controller - HTTP/HTTPS load balancing
module "ingress_nginx" {
  source = "./modules/ingress-nginx"
  count  = var.enable_ingress_nginx ? 1 : 0
  
  namespace = "ingress-nginx"
  
  depends_on = [module.eks]
}

# Cert Manager - Automatic TLS certificate management
# Integrates with Let's Encrypt for free certificates
module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.enable_cert_manager ? 1 : 0
  
  namespace    = "cert-manager"
  cluster_name = module.eks.cluster_name
  
  depends_on = [module.eks]
} 