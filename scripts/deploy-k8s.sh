#!/bin/bash

# Kubernetes Deployment Script
# This script deploys the microservices to Kubernetes using Kustomize

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${ENVIRONMENT:-development}"
NAMESPACE="microservices-${ENVIRONMENT}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -k|--kubeconfig)
      KUBECONFIG="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -e, --environment  Environment to deploy to (development/staging/production)"
      echo "  -n, --namespace    Kubernetes namespace"
      echo "  -k, --kubeconfig   Path to kubeconfig file"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}Deploying to ${ENVIRONMENT} environment${NC}"
echo "Namespace: ${NAMESPACE}"
echo "Kubeconfig: ${KUBECONFIG}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if kustomize is installed
if ! command -v kustomize &> /dev/null; then
    echo -e "${YELLOW}kustomize is not installed. Using kubectl kustomize instead.${NC}"
    KUSTOMIZE_CMD="kubectl kustomize"
else
    KUSTOMIZE_CMD="kustomize build"
fi

# Check if the kubeconfig file exists
if [ ! -f "$KUBECONFIG" ]; then
    echo -e "${RED}Kubeconfig file not found: $KUBECONFIG${NC}"
    exit 1
fi

# Export KUBECONFIG
export KUBECONFIG

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating namespace if it doesn't exist...${NC}"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Deploy using Kustomize
echo -e "${YELLOW}Building Kubernetes manifests...${NC}"
if [ -d "k8s/overlays/${ENVIRONMENT}" ]; then
    ${KUSTOMIZE_CMD} "k8s/overlays/${ENVIRONMENT}" | kubectl apply -n "${NAMESPACE}" -f -
else
    echo -e "${YELLOW}No overlay found for ${ENVIRONMENT}, using base configuration...${NC}"
    ${KUSTOMIZE_CMD} "k8s/base" | kubectl apply -n "${NAMESPACE}" -f -
fi

# Wait for deployments to be ready
echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment --all -n "${NAMESPACE}"

# Show deployment status
echo -e "${GREEN}Deployment completed successfully!${NC}"
kubectl get deployments,services,ingress -n "${NAMESPACE}"

# Show pod status
echo -e "\n${YELLOW}Pod Status:${NC}"
kubectl get pods -n "${NAMESPACE}"

# Show ingress URL if available
INGRESS_URL=$(kubectl get ingress -n "${NAMESPACE}" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "")
if [ ! -z "$INGRESS_URL" ]; then
    echo -e "\n${GREEN}Application is available at: https://${INGRESS_URL}${NC}"
fi 