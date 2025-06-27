#!/bin/bash

# Kong Gateway Setup Script
# This script initializes Kong Gateway with basic configuration

set -e

KONG_ADMIN_URL=${KONG_ADMIN_URL:-http://localhost:8001}

echo "🚀 Setting up Kong Gateway..."
echo "Kong Admin URL: $KONG_ADMIN_URL"

# Wait for Kong to be ready
echo "⏳ Waiting for Kong to be ready..."
until curl -s "$KONG_ADMIN_URL/status" > /dev/null; do
    echo "Waiting for Kong..."
    sleep 2
done
echo "✅ Kong is ready!"

# Function to create or update a service
create_service() {
    local name=$1
    local url=$2
    
    echo "📦 Creating service: $name"
    curl -s -X PUT "$KONG_ADMIN_URL/services/$name" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$name\",
            \"url\": \"$url\",
            \"retries\": 5,
            \"connect_timeout\": 60000,
            \"write_timeout\": 60000,
            \"read_timeout\": 60000
        }" > /dev/null
    echo "✅ Service $name created/updated"
}

# Function to create or update a route
create_route() {
    local service=$1
    local path=$2
    local route_name="${service}-route"
    
    echo "🛣️  Creating route for $service: $path"
    curl -s -X PUT "$KONG_ADMIN_URL/services/$service/routes/$route_name" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$route_name\",
            \"paths\": [\"$path\"],
            \"strip_path\": false,
            \"preserve_host\": true,
            \"methods\": [\"GET\", \"POST\", \"PUT\", \"DELETE\", \"PATCH\", \"OPTIONS\"]
        }" > /dev/null
    echo "✅ Route created/updated"
}

# Function to enable a plugin globally
enable_global_plugin() {
    local plugin_name=$1
    local config=$2
    
    echo "🔌 Enabling global plugin: $plugin_name"
    curl -s -X POST "$KONG_ADMIN_URL/plugins" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$plugin_name\",
            \"config\": $config
        }" > /dev/null || echo "Plugin might already exist"
    echo "✅ Plugin $plugin_name enabled"
}

# Create services
create_service "user-service" "http://host.docker.internal:3001"
create_service "auth-service" "http://host.docker.internal:3002"
create_service "notification-service" "http://host.docker.internal:3003"

# Create routes
create_route "user-service" "/api/users"
create_route "auth-service" "/api/auth"
create_route "notification-service" "/api/notifications"

# Create health check route
echo "🏥 Creating health check route"
curl -s -X PUT "$KONG_ADMIN_URL/services/health-check" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "health-check",
        "url": "http://host.docker.internal:3001/health"
    }' > /dev/null

curl -s -X PUT "$KONG_ADMIN_URL/services/health-check/routes/health-route" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "health-route",
        "paths": ["/health"],
        "methods": ["GET"]
    }' > /dev/null
echo "✅ Health check route created"

# Enable global plugins
echo "🔧 Enabling global plugins..."

# CORS
enable_global_plugin "cors" '{
    "origins": ["*"],
    "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    "headers": ["Accept", "Accept-Version", "Content-Length", "Content-MD5", "Content-Type", "Date", "X-Auth-Token", "Authorization"],
    "exposed_headers": ["X-Auth-Token"],
    "credentials": true,
    "max_age": 3600
}'

# Rate Limiting
enable_global_plugin "rate-limiting" '{
    "minute": 100,
    "hour": 10000,
    "policy": "local"
}'

# Prometheus Metrics
enable_global_plugin "prometheus" '{
    "per_consumer": true,
    "status_code_metrics": true,
    "latency_metrics": true,
    "bandwidth_metrics": true,
    "upstream_health_metrics": true
}'

# Create sample consumers
echo "👥 Creating sample consumers..."

# Admin consumer
curl -s -X PUT "$KONG_ADMIN_URL/consumers/admin" \
    -H "Content-Type: application/json" \
    -d '{"username": "admin", "custom_id": "admin-001"}' > /dev/null

# Create API key for admin
curl -s -X POST "$KONG_ADMIN_URL/consumers/admin/key-auth" \
    -H "Content-Type: application/json" \
    -d '{"key": "admin-api-key-12345"}' > /dev/null || echo "Key might already exist"

echo "✅ Admin consumer created with API key: admin-api-key-12345"

# Service account consumer
curl -s -X PUT "$KONG_ADMIN_URL/consumers/service-account" \
    -H "Content-Type: application/json" \
    -d '{"username": "service-account", "custom_id": "service-001"}' > /dev/null

# Create API key for service account
curl -s -X POST "$KONG_ADMIN_URL/consumers/service-account/key-auth" \
    -H "Content-Type: application/json" \
    -d '{"key": "service-api-key-67890"}' > /dev/null || echo "Key might already exist"

echo "✅ Service account created with API key: service-api-key-67890"

# Display summary
echo ""
echo "🎉 Kong Gateway setup complete!"
echo ""
echo "📋 Summary:"
echo "  - Kong Proxy: http://localhost:8000"
echo "  - Kong Admin API: http://localhost:8001"
echo "  - Kong Manager: http://localhost:8002"
echo "  - Konga UI: http://localhost:1337"
echo ""
echo "📚 Available routes:"
echo "  - GET/POST/PUT/DELETE http://localhost:8000/api/users"
echo "  - GET/POST/PUT/DELETE http://localhost:8000/api/auth"
echo "  - GET/POST/PUT/DELETE http://localhost:8000/api/notifications"
echo "  - GET http://localhost:8000/health"
echo ""
echo "🔑 Sample API keys:"
echo "  - Admin: admin-api-key-12345"
echo "  - Service: service-api-key-67890"
echo ""
echo "📝 Example usage:"
echo "  curl http://localhost:8000/api/users -H 'apikey: admin-api-key-12345'"
echo ""