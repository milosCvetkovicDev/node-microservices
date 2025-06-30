# Authentication Services - Quick Start Guide

This guide will help you quickly set up and run the authentication services using Docker.

## Prerequisites

- Docker and Docker Compose installed
- Make installed (optional, for using Makefile commands)
- curl and jq installed (for setup scripts)

## Quick Start Steps

### 1. Setup Environment

```bash
# Create auth service environment file
./scripts/setup-auth-env.sh
```

### 2. Build Docker Images

```bash
# Using Make
make docker-build-auth

# Or manually
docker build -f apps/auth-service/Dockerfile -t auth-service:latest .
docker build -f apps/auth-frontend/Dockerfile -t auth-frontend:latest .
```

### 3. Start All Services

```bash
# Using Make (recommended)
make docker-auth-up

# Or manually
docker-compose up -d postgres redis keycloak-db keycloak
# Wait for Keycloak to be ready (check http://localhost:8180)
./scripts/setup-keycloak.sh
docker-compose up -d auth-service auth-frontend
```

### 4. Update Keycloak Client Secret

After running the setup script, you'll see output like:
```
auth-service client created with secret: <CLIENT_SECRET>
```

Update `apps/auth-service/.env` with this secret:
```
KEYCLOAK_CLIENT_SECRET=<CLIENT_SECRET>
```

Then restart the auth-service:
```bash
docker-compose restart auth-service
```

### 5. Access the Applications

- **Auth Frontend**: http://localhost:4200
- **Auth Service API**: http://localhost:3334/api
- **Keycloak Admin**: http://localhost:8180 (admin/admin)

## Testing the System

1. **Register a new user**:
   - Go to http://localhost:4200/register
   - Fill in the registration form
   - Submit to create a new account

2. **Login**:
   - Go to http://localhost:4200/login
   - Use your credentials or click "Sign in with Keycloak SSO"
   - You'll be redirected to the dashboard

3. **Check API Health**:
   ```bash
   curl http://localhost:3334/api/auth/health
   ```

## Troubleshooting

### Build Errors

If you encounter npm dependency errors during Docker build:
- The Dockerfiles are configured to use `--legacy-peer-deps`
- This handles version conflicts in the Nx workspace

### Keycloak Not Ready

If Keycloak takes too long to start:
```bash
# Check Keycloak logs
docker-compose logs keycloak

# Check if it's running
docker-compose ps keycloak
```

### Auth Service Can't Connect

If auth-service can't connect to Keycloak:
1. Ensure Keycloak is running: `docker-compose ps`
2. Check the KEYCLOAK_URL in `.env` (should be `http://keycloak:8080` for Docker)
3. Verify the client secret is correctly set

### Cookies Not Working

If authentication cookies aren't being set:
1. Ensure you're accessing via http://localhost (not 127.0.0.1)
2. Check browser console for CORS errors
3. Verify `withCredentials: true` is set in the frontend

## Cleanup

To stop all services:
```bash
make docker-down
```

To stop and remove all data:
```bash
docker-compose down -v
```

## Next Steps

- Configure production environment variables
- Set up SSL/TLS for production
- Configure Keycloak with your organization's settings
- Add additional authentication providers in Keycloak
- Set up monitoring and logging 