# Quick Start Guide

Get up and running with the Node.js Microservices project in under 5 minutes! This guide will walk you through the fastest path to a working development environment.

## 🎯 Overview

By the end of this guide, you will have:
- ✅ All services running locally
- ✅ A working database with sample data
- ✅ The ability to make API requests
- ✅ Hot reload enabled for development

## 📋 Prerequisites Check

Before starting, ensure you have these tools installed:

```bash
# Check Node.js version (should be v20.x or higher)
node --version

# Check pnpm version (should be v8.x or higher)
pnpm --version

# Check Docker version (should be v24.x or higher)
docker --version

# Check Docker Compose version
docker-compose --version
```

If any tools are missing, see our [Prerequisites Guide](./prerequisites.md).

## 🚀 Quick Setup (3 minutes)

### Step 1: Clone and Install (1 minute)

```bash
# Clone the repository
git clone https://github.com/yourusername/node-microservices.git
cd node-microservices

# Install dependencies
pnpm install
```

### Step 2: Environment Setup (30 seconds)

```bash
# Copy example environment file
cp .env.example .env

# The default values will work for local development
# No need to edit unless you have specific requirements
```

### Step 3: Start Development Environment (1 minute)

```bash
# Start all services with hot reload
make docker-up

# Or using docker compose directly
docker compose up
```

This starts all services with hot reload enabled. You should see:
```
NAME                    STATUS    PORTS
postgres                Running   0.0.0.0:5432->5432/tcp
keycloak                Running   0.0.0.0:8180->8080/tcp
auth-service            Running   0.0.0.0:3334->3334/tcp
stripe-service          Running   0.0.0.0:3333->3333/tcp
pgadmin                 Running   0.0.0.0:5050->80/tcp
```

### Step 4: Verify Services (30 seconds)

Wait for services to initialize (about 30 seconds), then verify:

```bash
# Check all containers are healthy
docker compose ps

# View logs
docker compose logs -f auth-service
```

## ✅ Verify Everything Works

### Check Service Health

Open your browser and visit:

- **Auth Service**: http://localhost:3334/api/auth/health
- **Stripe Service**: http://localhost:3333/liveness
- **Keycloak**: http://localhost:8180 (admin/admin)

Each should return:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "service": "service-name",
  "version": "1.0.0"
}
```

### Make Your First API Request

#### 1. Register a New User

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "quickstart@example.com",
    "password": "QuickStart123!",
    "name": "Quick Start User"
  }'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "email": "quickstart@example.com",
      "name": "Quick Start User"
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

#### 2. Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "quickstart@example.com",
    "password": "QuickStart123!"
  }'
```

#### 3. Get User Profile

```bash
# Replace <token> with the token from login response
curl -X GET http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer <token>"
```

## 🛠 Development Tools

### Prisma Studio (Database GUI)

```bash
# Open Prisma Studio to view and edit data
pnpm prisma:studio
```

Visit http://localhost:5555 to explore your database.

### API Documentation

```bash
# View Swagger documentation
open http://localhost:3000/api-docs
```

### Logs Monitoring

```bash
# View logs for all services
pnpm logs

# View logs for specific service
pnpm logs:api-gateway
pnpm logs:user-service
```

## 🔄 Hot Reload

Development containers support hot reload via Nx watch mode:

1. Edit any file in `apps/auth-service/src/` or `apps/stripe-service/src/`
2. Save the file
3. Nx automatically detects changes and recompiles
4. Changes are reflected within seconds

**View hot reload in action:**
```bash
# Watch auth-service logs for recompilation
docker compose logs -f auth-service
```

**Troubleshooting hot reload:**
```bash
# If changes aren't detected, restart the container
docker compose restart auth-service

# Clear Nx cache
docker compose exec auth-service npx nx reset
```

## 🧪 Quick Testing

### Run Unit Tests

```bash
# Test all services
pnpm test

# Test specific service
pnpm nx test user-service
```

### Run Integration Tests

```bash
# Ensure services are running first
pnpm test:integration
```

## 📱 Using Postman/Insomnia

We provide a Postman collection for easy API testing:

1. Import `docs/postman/microservices-collection.json`
2. Set environment to "Local Development"
3. Start making requests!

## 🆘 Troubleshooting Quick Fixes

### Services Won't Start

```bash
# Check container logs
docker compose logs auth-service

# Rebuild container
docker compose build --no-cache auth-service

# Clear Nx cache
docker compose exec auth-service npx nx reset
```

### Database Connection Issues

```bash
# Check if PostgreSQL is running
docker compose ps postgres

# Restart database
docker compose restart postgres

# Check logs
docker compose logs postgres
```

### Port Already in Use

```bash
# Find process using port 3334
lsof -i :3334

# Kill the process
kill -9 <PID>
```

### Reset Everything

```bash
# Stop all services
make docker-down

# Remove all containers and volumes
make docker-clean

# Start fresh
make docker-up
```

## 🎉 What's Next?

Congratulations! You now have a fully functional microservices development environment. Here's what to explore next:

1. **[Create Your First Feature](./first-feature.md)** - Add a new endpoint
2. **[Understanding the Architecture](../architecture/system-overview.md)** - Deep dive into the system design
3. **[Development Workflow](../development/workflow.md)** - Best practices for development
4. **[Testing Guide](../development/testing.md)** - Write comprehensive tests

## 💡 Pro Tips

1. **Use VS Code Tasks**: Press `Cmd+Shift+P` → "Tasks: Run Task" for quick commands
2. **Watch Mode**: Use `pnpm nx serve user-service --watch` for auto-reload
3. **Debug Mode**: Use VS Code debugger with provided launch configurations
4. **Multiple Terminals**: Use tmux or VS Code's integrated terminal for managing multiple services

## 📚 Additional Resources

- [Full Documentation](../README.md)
- [API Reference](../api/README.md)
- [Troubleshooting Guide](../operations/troubleshooting.md)
- [Video Tutorials](https://youtube.com/playlist?example)

---

**Need help?** Join our [Slack channel](https://slack.example.com) or check the [FAQ](./faq.md).

**Found an issue?** Please [report it](https://github.com/yourusername/node-microservices/issues/new). 