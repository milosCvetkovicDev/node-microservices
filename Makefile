# Makefile for Node Microservices

.PHONY: help install dev build test lint format clean docker-up docker-down k8s-deploy terraform-init terraform-plan terraform-apply

# Default target
help:
	@echo "Available commands:"
	@echo "  make install          - Install dependencies"
	@echo "  make dev              - Start development environment"
	@echo "  make build            - Build all applications"
	@echo "  make test             - Run tests"
	@echo "  make lint             - Run linting"
	@echo "  make format           - Format code"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make docker-up        - Start Docker services"
	@echo "  make docker-down      - Stop Docker services"
	@echo "  make k8s-deploy       - Deploy to Kubernetes"
	@echo "  make terraform-init   - Initialize Terraform"
	@echo "  make terraform-plan   - Plan Terraform changes"
	@echo "  make terraform-apply  - Apply Terraform changes"

# Install dependencies
install:
	npm install

# Start development environment
dev: docker-up
	npm run nx serve api-gateway

# Build all applications
build:
	npm run nx run-many --target=build --all --configuration=production

# Run tests
test:
	npm run test

# Run linting
lint:
	npm run lint

# Format code
format:
	npm run format

# Clean build artifacts
clean:
	rm -rf dist node_modules .nx

# Docker commands
docker-up:
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 10
	@echo "Services are running:"
	@echo "  PostgreSQL: localhost:5432"
	@echo "  Redis: localhost:6379"
	@echo "  RabbitMQ: localhost:15672"
	@echo "  PgAdmin: localhost:5050"
	@echo "  Prometheus: localhost:9090"
	@echo "  Grafana: localhost:3001"

docker-down:
	docker-compose down

docker-clean:
	docker-compose down -v

# Kubernetes commands
k8s-deploy-dev:
	./scripts/deploy-k8s.sh -e development

k8s-deploy-staging:
	./scripts/deploy-k8s.sh -e staging

k8s-deploy-prod:
	./scripts/deploy-k8s.sh -e production

# Terraform commands
terraform-init:
	./scripts/deploy-terraform.sh -a init

terraform-plan:
	./scripts/deploy-terraform.sh -a plan

terraform-apply:
	./scripts/deploy-terraform.sh -a apply

terraform-destroy:
	./scripts/deploy-terraform.sh -a destroy

# Service-specific commands
serve-api-gateway:
	npm run nx serve api-gateway

serve-user-service:
	npm run nx serve user-service

serve-auth-service:
	npm run nx serve auth-service

serve-notification-service:
	npm run nx serve notification-service

# Database commands
db-migrate:
	npm run nx run-many --target=db:migrate --all

db-seed:
	npm run nx run-many --target=db:seed --all

# Monitoring
logs-api-gateway:
	npm run nx logs api-gateway

logs-all:
	docker-compose logs -f

# Security
security-scan:
	npm audit
	trivy fs . 