# Kubernetes Deployment Guide

This guide covers deploying the Node.js microservices to Kubernetes, including local development with Minikube and production deployment on EKS.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development (Minikube)](#local-development-minikube)
3. [Production Deployment (EKS)](#production-deployment-eks)
4. [Deployment Strategies](#deployment-strategies)
5. [Configuration Management](#configuration-management)
6. [Monitoring & Observability](#monitoring--observability)
7. [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Tools

```bash
# Check tool versions
kubectl version --client
helm version
kustomize version
minikube version  # For local development
aws --version     # For EKS deployment

# Minimum versions required:
# kubectl: v1.28+
# helm: v3.12+
# kustomize: v5.0+
# minikube: v1.31+
# aws-cli: v2.13+
```

### Installing Tools

```bash
# macOS (using Homebrew)
brew install kubectl helm kustomize minikube awscli

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows (using Chocolatey)
choco install kubernetes-cli helm minikube awscli
```

## 🏠 Local Development (Minikube)

### 1. Start Minikube

```bash
# Start with sufficient resources
minikube start \
  --cpus=4 \
  --memory=8192 \
  --disk-size=30g \
  --kubernetes-version=v1.28.3 \
  --driver=docker

# Enable necessary addons
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### 2. Build and Load Images

```bash
# Build all service images
pnpm docker:build

# Load images into Minikube
minikube image load api-gateway:latest
minikube image load user-service:latest
minikube image load auth-service:latest
minikube image load notification-service:latest

# Verify images are loaded
minikube image ls | grep -E "(api-gateway|user-service|auth-service|notification-service)"
```

### 3. Deploy Infrastructure

```bash
# Create namespace
kubectl create namespace microservices-dev

# Deploy PostgreSQL
kubectl apply -f k8s/local/postgres.yaml -n microservices-dev

# Deploy Redis
kubectl apply -f k8s/local/redis.yaml -n microservices-dev

# Deploy RabbitMQ
kubectl apply -f k8s/local/rabbitmq.yaml -n microservices-dev

# Wait for infrastructure to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n microservices-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n microservices-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n microservices-dev --timeout=300s
```

### 4. Create Secrets and ConfigMaps

```bash
# Create secrets
kubectl create secret generic app-secrets \
  --from-literal=jwt-secret='your-super-secret-jwt-key' \
  --from-literal=database-password='postgres' \
  --from-literal=redis-password='redis_password' \
  -n microservices-dev

# Create ConfigMap
kubectl create configmap app-config \
  --from-file=k8s/config/application.yaml \
  -n microservices-dev

# Verify
kubectl get secrets -n microservices-dev
kubectl get configmaps -n microservices-dev
```

### 5. Deploy Microservices with Kustomize

```bash
# Deploy using Kustomize overlays
kubectl apply -k k8s/overlays/development -n microservices-dev

# Or deploy with Helm
helm install microservices ./helm/microservices \
  -f ./helm/microservices/values.development.yaml \
  -n microservices-dev

# Check deployment status
kubectl get deployments -n microservices-dev
kubectl get pods -n microservices-dev
kubectl get services -n microservices-dev
```

### 6. Access Services

```bash
# Port forward to access services
kubectl port-forward svc/api-gateway 3000:3000 -n microservices-dev &
kubectl port-forward svc/postgres 5432:5432 -n microservices-dev &
kubectl port-forward svc/redis 6379:6379 -n microservices-dev &

# Or use Minikube service command
minikube service api-gateway -n microservices-dev --url

# Access Kubernetes Dashboard
minikube dashboard

# View logs
kubectl logs -f deployment/api-gateway -n microservices-dev
```

## 🚀 Production Deployment (EKS)

### 1. Provision Infrastructure

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init -backend-config=backend-production.conf

# Review plan
terraform plan -var-file=environments/production.tfvars

# Apply infrastructure
terraform apply -var-file=environments/production.tfvars -auto-approve

# Configure kubectl
aws eks update-kubeconfig --name production-microservices-cluster --region us-east-1
```

### 2. Set Up Namespaces

```bash
# Create namespaces
kubectl create namespace microservices-prod
kubectl create namespace monitoring
kubectl create namespace ingress-nginx

# Label namespaces
kubectl label namespace microservices-prod environment=production
kubectl label namespace microservices-prod istio-injection=enabled  # If using Istio
```

### 3. Install Cluster Add-ons

```bash
# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Install Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --set autoDiscovery.clusterName=production-microservices-cluster \
  --set awsRegion=us-east-1 \
  -n kube-system

# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.metrics.enabled=true \
  -n ingress-nginx

# Install Cert Manager for TLS
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### 4. Deploy Monitoring Stack

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus and Grafana
helm install monitoring prometheus-community/kube-prometheus-stack \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  -n monitoring

# Deploy Loki for log aggregation
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack \
  --set grafana.enabled=false \
  --set promtail.enabled=true \
  -n monitoring
```

### 5. Deploy Applications

```bash
# Create production secrets
kubectl create secret generic app-secrets \
  --from-literal=jwt-secret="${JWT_SECRET}" \
  --from-literal=database-url="${DATABASE_URL}" \
  --from-literal=redis-url="${REDIS_URL}" \
  -n microservices-prod

# Deploy with Helm
helm upgrade --install microservices ./helm/microservices \
  -f ./helm/microservices/values.production.yaml \
  --set image.tag=${GIT_COMMIT_SHA} \
  --set ingress.host=api.example.com \
  -n microservices-prod

# Or deploy with Kustomize
kubectl apply -k k8s/overlays/production -n microservices-prod
```

### 6. Configure Ingress and TLS

```yaml
# k8s/production/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-secret
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 3000
```

```bash
# Apply ingress
kubectl apply -f k8s/production/ingress.yaml -n microservices-prod

# Create Let's Encrypt issuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: devops@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## 🔄 Deployment Strategies

### Blue-Green Deployment

```bash
# Deploy green version
helm upgrade --install microservices-green ./helm/microservices \
  -f ./helm/microservices/values.production.yaml \
  --set version=green \
  --set image.tag=${NEW_VERSION} \
  -n microservices-prod

# Test green deployment
kubectl run test-pod --rm -it --image=curlimages/curl -- \
  curl http://api-gateway-green:3000/health

# Switch traffic to green
kubectl patch service api-gateway -n microservices-prod \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Remove blue deployment after verification
helm uninstall microservices-blue -n microservices-prod
```

### Canary Deployment

```yaml
# k8s/canary/canary-deployment.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-canary
spec:
  selector:
    app: api-gateway
    version: canary
  ports:
  - port: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway-canary
spec:
  replicas: 1  # Start with 1 replica
  selector:
    matchLabels:
      app: api-gateway
      version: canary
  template:
    metadata:
      labels:
        app: api-gateway
        version: canary
    spec:
      containers:
      - name: api-gateway
        image: api-gateway:canary
        ports:
        - containerPort: 3000
```

```bash
# Deploy canary
kubectl apply -f k8s/canary/canary-deployment.yaml -n microservices-prod

# Gradually increase traffic using Istio or NGINX
# Example with NGINX annotations:
kubectl annotate ingress api-gateway-ingress \
  nginx.ingress.kubernetes.io/canary="true" \
  nginx.ingress.kubernetes.io/canary-weight="10"  # 10% traffic to canary
```

### Rolling Update

```bash
# Update deployment image
kubectl set image deployment/api-gateway \
  api-gateway=api-gateway:${NEW_VERSION} \
  -n microservices-prod

# Monitor rollout
kubectl rollout status deployment/api-gateway -n microservices-prod

# If issues occur, rollback
kubectl rollout undo deployment/api-gateway -n microservices-prod
```

## ⚙️ Configuration Management

### ConfigMaps for Environment Variables

```yaml
# k8s/config/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  NODE_ENV: "production"
  LOG_LEVEL: "info"
  PORT: "3000"
  ENABLE_METRICS: "true"
  RATE_LIMIT_WINDOW: "900000"
  RATE_LIMIT_MAX: "100"
```

### Secrets Management

```bash
# Using Kubernetes Secrets (base64 encoded)
kubectl create secret generic db-secret \
  --from-literal=username=dbuser \
  --from-literal=password='S3cur3P@ssw0rd' \
  -n microservices-prod

# Using AWS Secrets Manager with External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets-system --create-namespace

# Create SecretStore
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretstore
  namespace: microservices-prod
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
EOF
```

### Environment-Specific Configuration

```bash
# Structure
k8s/
├── base/                    # Common configurations
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── development/        # Dev-specific patches
│   │   ├── kustomization.yaml
│   │   └── resources-patch.yaml
│   ├── staging/           # Staging-specific patches
│   │   ├── kustomization.yaml
│   │   └── replicas-patch.yaml
│   └── production/        # Prod-specific patches
│       ├── kustomization.yaml
│       ├── resources-patch.yaml
│       └── affinity-patch.yaml
```

## 📊 Monitoring & Observability

### Prometheus Metrics

```yaml
# Enable metrics in deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
```

### Custom Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Microservices Overview",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~'5..'}[5m])"
          }
        ]
      },
      {
        "title": "Response Time (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
          }
        ]
      }
    ]
  }
}
```

### Log Aggregation

```bash
# View logs from all pods
kubectl logs -l app=microservices -n microservices-prod --tail=100

# Stream logs
kubectl logs -f deployment/api-gateway -n microservices-prod

# Export logs for analysis
kubectl logs -l app=microservices -n microservices-prod --since=1h > logs.txt

# Query logs with Loki
logcli query '{namespace="microservices-prod"} |= "error"' --limit=50
```

## 🔧 Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n microservices-prod

# Common causes:
# 1. Image pull errors
kubectl get events --field-selector reason=Failed -n microservices-prod

# 2. Resource constraints
kubectl top nodes
kubectl describe node <node-name>

# 3. Missing secrets/configmaps
kubectl get secrets -n microservices-prod
kubectl get configmaps -n microservices-prod
```

#### Service Discovery Issues

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup api-gateway.microservices-prod.svc.cluster.local

# Check service endpoints
kubectl get endpoints -n microservices-prod

# Verify service selector matches pod labels
kubectl get svc api-gateway -o yaml -n microservices-prod
kubectl get pods -l app=api-gateway -n microservices-prod
```

#### Performance Issues

```bash
# Check resource usage
kubectl top pods -n microservices-prod
kubectl top nodes

# Scale horizontally
kubectl scale deployment api-gateway --replicas=5 -n microservices-prod

# Or use HPA
kubectl autoscale deployment api-gateway \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n microservices-prod
```

### Debugging Commands

```bash
# Get shell access to pod
kubectl exec -it <pod-name> -n microservices-prod -- /bin/sh

# Copy files from pod
kubectl cp <pod-name>:/app/logs/error.log ./error.log -n microservices-prod

# Port forward for local debugging
kubectl port-forward <pod-name> 9229:9229 -n microservices-prod

# Run one-off debug pod
kubectl run debug --image=node:20-alpine -it --rm --restart=Never -- /bin/sh
```

## 📚 Best Practices

### Resource Management

```yaml
# Always set resource requests and limits
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Health Checks

```yaml
# Configure liveness and readiness probes
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Security

```yaml
# Run as non-root user
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

### Pod Disruption Budgets

```yaml
# Ensure availability during updates
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-gateway-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: api-gateway
```

## 🔗 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kustomize Documentation](https://kustomize.io/)

---

**Last Updated**: January 2024
**Version**: 1.0.0
**Maintainer**: DevOps Team 