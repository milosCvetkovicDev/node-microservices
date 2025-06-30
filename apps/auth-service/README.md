# Auth Service

This is the authentication and authorization microservice for the Node.js microservices application.

## Features

- User authentication with Keycloak integration
- JWT token management with HTTP-only cookies
- User registration and login
- Token refresh mechanism
- Session management

## Environment Variables

Create a `.env` file in the `apps/auth-service` directory with the following variables:

```env
# Auth Service Environment Variables
NODE_ENV=development
PORT=3334

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_db

# Redis
REDIS_URL=redis://:redis_password@localhost:6379

# JWT Configuration
JWT_SECRET=jwt_secret_key_change_in_production
JWT_REFRESH_SECRET=jwt_refresh_secret_key_change_in_production

# Keycloak Configuration
KEYCLOAK_URL=http://localhost:8180
KEYCLOAK_REALM=microservices
KEYCLOAK_CLIENT_ID=auth-service
KEYCLOAK_CLIENT_SECRET=auth-service-secret
KEYCLOAK_ADMIN_USERNAME=admin
KEYCLOAK_ADMIN_PASSWORD=admin
```

## Running the Service

1. Start the infrastructure services (PostgreSQL, Redis, Keycloak):
   ```bash
   docker-compose up -d postgres redis keycloak keycloak-db
   ```

2. Wait for Keycloak to start (check http://localhost:8180)

3. Run the auth service:
   ```bash
   nx serve auth-service
   ```

## API Endpoints

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login with username and password
- `POST /api/auth/keycloak/validate` - Validate a Keycloak token
- `POST /api/auth/refresh` - Refresh the access token
- `POST /api/auth/logout` - Logout the current user
- `GET /api/auth/me` - Get current user profile
- `GET /api/auth/health` - Health check endpoint

## Security Features

- HTTP-only cookies for token storage
- CORS configured for frontend applications
- JWT token validation
- Keycloak integration for enterprise SSO
- Secure session management 