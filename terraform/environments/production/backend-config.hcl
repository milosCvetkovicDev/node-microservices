bucket         = "your-terraform-state-bucket"
key            = "node-microservices/production/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock" 