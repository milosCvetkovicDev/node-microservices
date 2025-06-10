#!/bin/bash

# Terraform Infrastructure Deployment Script
# This script manages the infrastructure deployment using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${ENVIRONMENT:-development}"
ACTION="${ACTION:-plan}"
AUTO_APPROVE="${AUTO_APPROVE:-false}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -a|--action)
      ACTION="$2"
      shift 2
      ;;
    --auto-approve)
      AUTO_APPROVE="true"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -e, --environment  Environment to deploy (development/staging/production)"
      echo "  -a, --action       Terraform action (init/plan/apply/destroy)"
      echo "  --auto-approve     Auto approve terraform apply/destroy"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    echo -e "${RED}Invalid environment: $ENVIRONMENT${NC}"
    echo "Valid environments: development, staging, production"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(init|plan|apply|destroy|output)$ ]]; then
    echo -e "${RED}Invalid action: $ACTION${NC}"
    echo "Valid actions: init, plan, apply, destroy, output"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install Terraform first.${NC}"
    exit 1
fi

# Set working directory
TERRAFORM_DIR="terraform/environments/${ENVIRONMENT}"

# Check if environment directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}Environment directory not found: $TERRAFORM_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}Terraform Deployment Script${NC}"
echo -e "${BLUE}===================================${NC}"
echo -e "Environment: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "Action: ${GREEN}${ACTION}${NC}"
echo -e "Directory: ${GREEN}${TERRAFORM_DIR}${NC}"
echo -e "${BLUE}===================================${NC}\n"

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Execute terraform action
case $ACTION in
    init)
        echo -e "${YELLOW}Initializing Terraform...${NC}"
        if [ -f "backend-config.hcl" ]; then
            terraform init -backend-config=backend-config.hcl
        else
            terraform init
        fi
        ;;
    
    plan)
        echo -e "${YELLOW}Running Terraform plan...${NC}"
        terraform plan -out=tfplan
        echo -e "\n${GREEN}Plan saved to: tfplan${NC}"
        echo -e "${YELLOW}To apply this plan, run: $0 -e ${ENVIRONMENT} -a apply${NC}"
        ;;
    
    apply)
        echo -e "${YELLOW}Applying Terraform changes...${NC}"
        if [ -f "tfplan" ] && [ "$AUTO_APPROVE" != "true" ]; then
            echo -e "${YELLOW}Found existing plan file. Do you want to use it? (yes/no)${NC}"
            read -r USE_PLAN
            if [ "$USE_PLAN" = "yes" ]; then
                terraform apply tfplan
            else
                if [ "$AUTO_APPROVE" = "true" ]; then
                    terraform apply -auto-approve
                else
                    terraform apply
                fi
            fi
        else
            if [ "$AUTO_APPROVE" = "true" ]; then
                terraform apply -auto-approve
            else
                terraform apply
            fi
        fi
        
        # Save outputs
        echo -e "\n${YELLOW}Saving outputs...${NC}"
        terraform output -json > outputs.json
        echo -e "${GREEN}Outputs saved to: outputs.json${NC}"
        
        # Get kubeconfig
        echo -e "\n${YELLOW}Updating kubeconfig...${NC}"
        aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw aws_region) 2>/dev/null || true
        ;;
    
    destroy)
        echo -e "${RED}WARNING: This will destroy all infrastructure in ${ENVIRONMENT}!${NC}"
        if [ "$AUTO_APPROVE" != "true" ]; then
            echo -e "${YELLOW}Are you sure you want to continue? Type 'yes' to confirm:${NC}"
            read -r CONFIRM
            if [ "$CONFIRM" != "yes" ]; then
                echo -e "${YELLOW}Destroy cancelled.${NC}"
                exit 0
            fi
        fi
        
        if [ "$AUTO_APPROVE" = "true" ]; then
            terraform destroy -auto-approve
        else
            terraform destroy
        fi
        ;;
    
    output)
        echo -e "${YELLOW}Terraform outputs:${NC}"
        terraform output
        ;;
esac

echo -e "\n${GREEN}Terraform action completed successfully!${NC}" 