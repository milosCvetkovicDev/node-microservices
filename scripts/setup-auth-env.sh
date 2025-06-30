#!/bin/bash

# Setup script for auth service environment variables

set -e

ENV_FILE="apps/auth-service/.env"

echo "Setting up auth service environment..."

# Check if .env file already exists
if [ -f "$ENV_FILE" ]; then
    echo ".env file already exists at $ENV_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file"
        exit 0
    fi
fi

# Create .env file
cat > "$ENV_FILE" << EOF
# Auth Service Environment Variables
NODE_ENV=development
PORT=3334

# Database
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/auth_db

# Redis (for Docker, use service name)
REDIS_URL=redis://:redis_password@redis:6379

# JWT Configuration
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)

# Keycloak Configuration (for Docker, use service name)
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_REALM=microservices
KEYCLOAK_CLIENT_ID=auth-service
KEYCLOAK_CLIENT_SECRET=<replace-with-actual-secret-from-setup-script>
KEYCLOAK_ADMIN_USERNAME=admin
KEYCLOAK_ADMIN_PASSWORD=admin
EOF

echo "Created $ENV_FILE with secure random JWT secrets"
echo ""
echo "IMPORTANT: Please update the KEYCLOAK_CLIENT_SECRET after running:"
echo "  ./scripts/setup-keycloak.sh"
echo ""
echo "The setup script will output the client secret that you need to add to the .env file" 