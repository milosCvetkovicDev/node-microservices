# Production Environment Configuration

terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    # Backend configuration will be provided via backend-config.hcl
  }
}

locals {
  environment = "production"
  region      = "us-east-1"
  
  # Production-specific configurations
  node_groups = {
    general = {
      name            = "general"
      instance_types  = ["t3.large"]
      min_size        = 3
      max_size        = 10
      desired_size    = 5
      disk_size       = 100
      
      labels = {
        role = "general"
      }
      
      taints = []
      
      tags = {
        Environment = local.environment
      }
    }
    
    compute = {
      name            = "compute"
      instance_types  = ["c5.xlarge"]
      min_size        = 2
      max_size        = 20
      desired_size    = 3
      disk_size       = 100
      
      labels = {
        role = "compute"
        workload = "cpu-intensive"
      }
      
      taints = [{
        key    = "compute"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      
      tags = {
        Environment = local.environment
      }
    }
  }
}

module "infrastructure" {
  source = "../../"
  
  project_name       = "node-microservices"
  environment        = local.environment
  aws_region         = local.region
  vpc_cidr          = "10.0.0.0/16"
  
  # EKS Configuration
  eks_cluster_version = "1.28"
  node_groups        = local.node_groups
  
  # Enable all production features
  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_ingress_nginx      = true
  enable_cert_manager       = true
  
  # Production domain
  domain_name = "api.production.example.com"
  
  tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
} 