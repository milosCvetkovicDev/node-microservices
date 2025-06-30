#!/bin/bash

# Keycloak Setup Script
# This script configures Keycloak with the necessary realm and clients

set -e

KEYCLOAK_URL=${KEYCLOAK_URL:-"http://localhost:8180"}
KEYCLOAK_USER=${KEYCLOAK_USER:-"admin"}
KEYCLOAK_PASSWORD=${KEYCLOAK_PASSWORD:-"admin"}
REALM_NAME=${REALM_NAME:-"microservices"}

echo "Waiting for Keycloak to be ready..."
until curl -s -f -o /dev/null "${KEYCLOAK_URL}/health/ready"; do
  echo "Waiting for Keycloak..."
  sleep 5
done

echo "Keycloak is ready. Getting admin token..."

# Get admin token
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${KEYCLOAK_USER}" \
  -d "password=${KEYCLOAK_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$ADMIN_TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

echo "Creating realm: ${REALM_NAME}"

# Create realm
curl -s -X POST "${KEYCLOAK_URL}/admin/realms" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "'${REALM_NAME}'",
    "enabled": true,
    "sslRequired": "external",
    "registrationAllowed": true,
    "loginWithEmailAllowed": true,
    "duplicateEmailsAllowed": false,
    "resetPasswordAllowed": true,
    "editUsernameAllowed": true,
    "bruteForceProtected": true
  }'

echo "Creating auth-frontend client..."

# Create auth-frontend client (public client for React app)
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "auth-frontend",
    "name": "Auth Frontend",
    "description": "React authentication frontend",
    "rootUrl": "http://localhost:4200",
    "adminUrl": "http://localhost:4200",
    "baseUrl": "http://localhost:4200",
    "surrogateAuthRequired": false,
    "enabled": true,
    "publicClient": true,
    "protocol": "openid-connect",
    "attributes": {
      "pkce.code.challenge.method": "S256"
    },
    "redirectUris": [
      "http://localhost:4200/*",
      "http://localhost:3000/*"
    ],
    "webOrigins": [
      "http://localhost:4200",
      "http://localhost:3000"
    ]
  }'

echo "Creating auth-service client..."

# Create auth-service client (confidential client for backend)
AUTH_SERVICE_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "auth-service",
    "name": "Auth Service",
    "description": "NestJS authentication service",
    "enabled": true,
    "publicClient": false,
    "protocol": "openid-connect",
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": true,
    "authorizationServicesEnabled": false,
    "attributes": {
      "saml.assertion.signature": "false",
      "saml.force.post.binding": "false",
      "saml.multivalued.roles": "false",
      "saml.encrypt": "false",
      "saml.server.signature": "false",
      "saml.server.signature.keyinfo.ext": "false",
      "exclude.session.state.from.auth.response": "false",
      "saml_force_name_id_format": "false",
      "saml.client.signature": "false",
      "tls.client.certificate.bound.access.tokens": "false",
      "saml.authnstatement": "false",
      "display.on.consent.screen": "false",
      "saml.onetimeuse.condition": "false"
    }
  }')

# Get the client ID to retrieve the secret
CLIENT_ID=$(echo $AUTH_SERVICE_RESPONSE | jq -r '.id')

if [ ! -z "$CLIENT_ID" ] && [ "$CLIENT_ID" != "null" ]; then
  # Get client secret
  CLIENT_SECRET=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_ID}/client-secret" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.value')
  
  echo "auth-service client created with secret: ${CLIENT_SECRET}"
  echo "Please update your .env file with:"
  echo "KEYCLOAK_CLIENT_SECRET=${CLIENT_SECRET}"
else
  echo "Client might already exist or there was an error creating it"
fi

echo "Creating default roles..."

# Create default roles
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "user", "description": "Default user role"}'

curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "admin", "description": "Administrator role"}'

echo "Keycloak setup completed successfully!"
echo ""
echo "You can access Keycloak admin console at: ${KEYCLOAK_URL}"
echo "Username: ${KEYCLOAK_USER}"
echo "Password: ${KEYCLOAK_PASSWORD}"
echo ""
echo "Realm: ${REALM_NAME}"
echo "Clients created: auth-frontend (public), auth-service (confidential)" 