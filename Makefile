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
	@echo "  make kong-setup       - Initialize Kong Gateway configuration"
	@echo "  make kong-status      - Check Kong Gateway status"
	@echo "  make kong-services    - List Kong services"
	@echo "  make kong-routes      - List Kong routes"
	@echo "  make kong-logs        - View Kong logs"
	@echo "  make k8s-deploy       - Deploy to Kubernetes"
	@echo "  make terraform-init   - Initialize Terraform"
	@echo "  make terraform-plan   - Plan Terraform changes"
	@echo "  make terraform-apply  - Apply Terraform changes"

# Install dependencies
install:
	npm install

# Start development environment
dev: docker-up
	@echo "Kong Gateway is running at http://localhost:8000"
	@echo "Start your microservices with: make serve-<service-name>"
	@echo "Available services: user-service, auth-service, notification-service"

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
# Detect docker compose command (new vs old style)
DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null || echo "docker compose")

docker-up:
	$(DOCKER_COMPOSE) up -d
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
	@if [ ! -f apps/stripe-service/.env ]; then \
	  echo "Creating empty apps/stripe-service/.env file..."; \
	  touch apps/stripe-service/.env; \
	fi
	$(DOCKER_COMPOSE) down

docker-clean:
	$(DOCKER_COMPOSE) down -v

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
serve-user-service:
	npm run nx serve user-service

serve-auth-service:
	npm run nx serve auth-service

serve-notification-service:
	npm run nx serve notification-service

# Kong Gateway commands
kong-status:
	@echo "Checking Kong status..."
	@curl -s http://localhost:8001/status | jq '.' || echo "Kong is not running"

kong-services:
	@echo "Listing Kong services..."
	@curl -s http://localhost:8001/services | jq '.data[]' || echo "No services found"

kong-routes:
	@echo "Listing Kong routes..."
	@curl -s http://localhost:8001/routes | jq '.data[]' || echo "No routes found"

kong-reload:
	@echo "Reloading Kong configuration..."
	@docker-compose exec kong kong reload

kong-logs:
	$(DOCKER_COMPOSE) logs -f kong

kong-admin:
	@echo "Kong Admin API available at: http://localhost:8001"
	@echo "Kong Manager GUI available at: http://localhost:8002"
	@echo "Konga UI available at: http://localhost:1337"

kong-setup:
	@echo "Running Kong setup script..."
	@./scripts/setup-kong.sh

# Database commands
db-migrate:
	npm run nx run-many --target=db:migrate --all

db-seed:
	npm run nx run-many --target=db:seed --all

# Monitoring
logs-all:
	$(DOCKER_COMPOSE) logs -f

# Security
security-scan:
	npm audit
	trivy fs . 