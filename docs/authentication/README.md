# Authentication and Authorization System

This document describes the complete authentication and authorization system implemented using NestJS, React, and Keycloak.

## Architecture Overview

The authentication system consists of three main components:

1. **Keycloak** - Identity and Access Management server
2. **Auth Service** - NestJS backend service handling authentication logic
3. **Auth Frontend** - React application providing the user interface

## Components

### 1. Keycloak

Keycloak provides enterprise-grade identity management with features like:
- Single Sign-On (SSO)
- Identity brokering and social login
- User federation
- Admin console for user management
- Fine-grained authorization services

**Access**: http://localhost:8180
**Admin Credentials**: admin/admin

### 2. Auth Service (NestJS)

The auth service acts as a bridge between the frontend and Keycloak, providing:
- User registration and login endpoints
- JWT token generation and validation
- HTTP-only cookie management
- User synchronization with local database
- Token refresh mechanism

**Port**: 3334
**API Base**: http://localhost:3334/api

### 3. Auth Frontend (React)

The frontend provides:
- User registration and login forms
- Dashboard for authenticated users
- Protected routes
- Automatic token refresh
- Keycloak SSO integration

**Port**: 4200
**URL**: http://localhost:4200

## Quick Start

### 1. Start Infrastructure

```bash
# Start all infrastructure services
docker-compose up -d postgres redis keycloak-db keycloak

# Wait for Keycloak to be ready (check http://localhost:8180)
```

### 2. Configure Keycloak

```bash
# Run the setup script to create realm and clients
./scripts/setup-keycloak.sh
```

This will create:
- `microservices` realm
- `auth-frontend` client (public)
- `auth-service` client (confidential)
- Default roles: `user`, `admin`

### 3. Configure Auth Service

Create `.env` file in `apps/auth-service/`:

```env
NODE_ENV=development
PORT=3334
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auth_db
REDIS_URL=redis://:redis_password@localhost:6379
JWT_SECRET=jwt_secret_key_change_in_production
JWT_REFRESH_SECRET=jwt_refresh_secret_key_change_in_production
KEYCLOAK_URL=http://localhost:8180
KEYCLOAK_REALM=microservices
KEYCLOAK_CLIENT_ID=auth-service
KEYCLOAK_CLIENT_SECRET=<client-secret-from-setup-script>
```

### 4. Start Services

```bash
# Terminal 1: Start auth service
nx serve auth-service

# Terminal 2: Start auth frontend
nx serve auth-frontend
```

## Authentication Flow

### Standard Login
1. User enters credentials in the login form
2. Frontend sends credentials to auth service
3. Auth service validates with Keycloak
4. Auth service generates JWT tokens
5. Tokens are set as HTTP-only cookies
6. User is redirected to dashboard

### Keycloak SSO
1. User clicks "Login with Keycloak"
2. User is redirected to Keycloak login
3. After successful login, redirected back with token
4. Frontend validates token with auth service
5. Auth service sets HTTP-only cookies
6. User is redirected to dashboard

### Token Refresh
1. Axios interceptor detects 401 response
2. Automatically calls refresh endpoint
3. New tokens are set in cookies
4. Original request is retried

## API Endpoints

### Auth Service Endpoints

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login with username/password
- `POST /api/auth/keycloak/validate` - Validate Keycloak token
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user info
- `GET /api/auth/health` - Health check

## Security Features

### HTTP-Only Cookies
- Prevents XSS attacks
- Cannot be accessed by JavaScript
- Automatically sent with requests

### CORS Configuration
- Configured for specific origins
- Credentials enabled for cookie support

### Token Security
- Short-lived access tokens (1 day)
- Longer refresh tokens (7 days)
- Automatic refresh before expiration

### Keycloak Integration
- Centralized user management
- Support for MFA
- Role-based access control
- Audit logging

## Deployment

### Docker Deployment

```bash
# Build images
docker build -f apps/auth-service/Dockerfile -t auth-service .
docker build -f apps/auth-frontend/Dockerfile -t auth-frontend .

# Run with docker-compose
docker-compose up -d
```

### Kubernetes Deployment

The services are configured for Kubernetes deployment with:
- ConfigMaps for configuration
- Secrets for sensitive data
- Health checks and readiness probes
- Horizontal Pod Autoscaling

## Troubleshooting

### Common Issues

1. **Keycloak Connection Failed**
   - Ensure Keycloak is running: `docker-compose ps`
   - Check Keycloak logs: `docker-compose logs keycloak`
   - Verify URL in auth service config

2. **Cookie Not Set**
   - Check CORS configuration
   - Ensure `withCredentials: true` in axios
   - Verify same-site cookie settings

3. **Token Refresh Failed**
   - Check refresh token expiration
   - Verify JWT_REFRESH_SECRET matches
   - Check Redis connection

### Debug Mode

Enable debug logging:
```env
DEBUG=auth:*
LOG_LEVEL=debug
```

## Best Practices

1. **Production Configuration**
   - Use strong JWT secrets
   - Enable HTTPS for all services
   - Configure secure cookie settings
   - Use environment-specific Keycloak realms

2. **Security**
   - Regular token rotation
   - Implement rate limiting
   - Monitor failed login attempts
   - Regular security audits

3. **Monitoring**
   - Track authentication metrics
   - Monitor token refresh rates
   - Alert on unusual patterns
   - Log security events

## Future Enhancements

- [ ] Multi-factor authentication (MFA)
- [ ] Social login providers
- [ ] Password reset flow
- [ ] Email verification
- [ ] Session management UI
- [ ] Role-based UI components
- [ ] Audit logging dashboard 