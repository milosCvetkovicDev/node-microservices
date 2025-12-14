# Development Workflow Guide

This guide covers the day-to-day development workflow for the Node.js Microservices project, including Docker-based development with hot reload.

## 🚀 Quick Start

### Starting the Development Environment

```bash
# Start all services with hot reload
make docker-up

# Or using docker compose directly
docker compose up
```

This starts:
- **PostgreSQL** (port 5432)
- **Keycloak** (port 8180)
- **Auth Service** (port 3334) - with hot reload
- **Stripe Service** (port 3333) - with hot reload
- **pgAdmin** (port 5050)

### Stopping Services

```bash
# Stop all services
make docker-down

# Stop and remove volumes (reset data)
make docker-clean
```

## 🔥 Hot Reload Development

### How It Works

The development Dockerfiles use Nx's serve command with watch mode:

1. Source code is mounted as a Docker volume
2. Nx watches for file changes
3. On change, the service automatically recompiles
4. No need to rebuild Docker images

### File Structure

```
apps/
├── auth-service/
│   ├── Dockerfile.dev     # Development (hot reload)
│   ├── Dockerfile.prod    # Production (optimized)
│   └── src/               # Mounted as volume
└── stripe-service/
    ├── Dockerfile.dev     # Development (hot reload)
    ├── Dockerfile.prod    # Production (optimized)
    └── src/               # Mounted as volume
```

### Making Changes

1. Edit any file in `apps/<service>/src/`
2. Save the file
3. Watch the container logs for recompilation:
   ```bash
   docker compose logs -f auth-service
   ```
4. Changes are reflected within seconds

### Debugging Hot Reload Issues

If changes aren't being detected:

```bash
# Check if volume is mounted correctly
docker compose exec auth-service ls -la /app/apps/auth-service

# Verify Nx is watching
docker compose logs auth-service | grep -i "watch"

# Clear Nx cache
docker compose exec auth-service npx nx reset

# Rebuild container
docker compose up -d --build auth-service
```

## 📁 Environment Variables

### Development

Environment variables are loaded from `.env` files via `env_file` in docker-compose:

```yaml
auth-service:
  env_file:
    - ./apps/auth-service/.env
```

### Creating Environment Files

```bash
# Copy example files
cp apps/auth-service/.env.example apps/auth-service/.env
cp apps/stripe-service/.env.example apps/stripe-service/.env

# Edit with your values
nano apps/auth-service/.env
```

### Important: Never Commit Secrets

The `.env` files are git-ignored. Never bake secrets into Docker images.

## 🧪 Running Tests

### Unit Tests

```bash
# Test all services
npm run test

# Test specific service
npx nx test auth-service

# Watch mode
npx nx test auth-service --watch
```

### E2E Tests

```bash
# Ensure services are running
make docker-up

# Run E2E tests
npx nx e2e auth-service-e2e
```

## 🔨 Building for Production

### Build Production Images

```bash
# Build all production images
make docker-build-prod

# Build specific service
docker build -f apps/auth-service/Dockerfile.prod -t auth-service:latest .
```

### Production Image Features

- Multi-stage build (smaller image)
- `dumb-init` for proper signal handling
- Non-root user (nodejs:1001)
- `NODE_ENV=production`
- Only production dependencies

## 📝 Common Commands

| Command | Description |
|---------|-------------|
| `make docker-up` | Start dev environment with hot reload |
| `make docker-down` | Stop all services |
| `make docker-build-prod` | Build production images |
| `npx nx serve auth-service` | Run service locally (no Docker) |
| `npx nx build auth-service` | Build service |
| `npx nx test auth-service` | Run unit tests |
| `docker compose logs -f auth-service` | Follow service logs |

## 🔧 VS Code Integration

### Recommended Extensions

- Docker
- Nx Console
- ESLint
- Prettier

### Launch Configuration

Add to `.vscode/launch.json` for debugging:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Attach to Auth Service",
      "port": 9229,
      "restart": true,
      "localRoot": "${workspaceFolder}/apps/auth-service",
      "remoteRoot": "/app/apps/auth-service"
    }
  ]
}
```

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check build logs
docker compose build auth-service --no-cache

# Check container logs
docker compose logs auth-service

# Check for port conflicts
lsof -i :3334
```

### Database Connection Issues

```bash
# Verify PostgreSQL is running
docker compose ps postgres

# Check PostgreSQL logs
docker compose logs postgres

# Test connection
docker compose exec postgres psql -U postgres -d microservices
```

### Keycloak Issues

```bash
# Wait for Keycloak to be ready
docker compose logs keycloak | grep -i "started"

# Access Keycloak admin
open http://localhost:8180
# Login: admin / admin
```

## 📚 Additional Resources

- [Architecture Overview](../architecture/system-overview.md)
- [Kubernetes Deployment](../deployment/kubernetes.md)
- [Troubleshooting Guide](../operations/troubleshooting.md)

---

**Last Updated**: December 2024
**Version**: 1.0.0
