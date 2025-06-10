# Node Microservices - NX Workspace

A modern monorepo setup for Node.js microservices using [Nx](https://nx.dev), a powerful build system with first-class monorepo support and powerful integrations.

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
- [Project Structure](#️-project-structure)
- [Architecture Overview](#-architecture-overview)
- [Development Guide](#-development-guide)
- [Environment Configuration](#-environment-configuration)
- [Testing Strategy](#-testing-strategy)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Deployment](#-deployment)
- [Monitoring & Logging](#-monitoring--logging)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Node.js (v18.0.0 or higher) - [Download](https://nodejs.org/)
- npm (v8.0.0 or higher)
- Git - [Download](https://git-scm.com/)
- Docker & Docker Compose (optional, for containerization) - [Download](https://www.docker.com/)

### Recommended Tools
- Visual Studio Code with Nx Console extension
- Postman or Insomnia for API testing
- MongoDB Compass (if using MongoDB)
- pgAdmin (if using PostgreSQL)

## 🚀 Getting Started

### Installation

1. Clone the repository:
   ```bash
   git clone <your-repository-url>
   cd node-microservices
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Verify the installation:
   ```bash
   npx nx --version
   npx nx run-many --target=lint --all
   ```

### Quick Start

```bash
# Generate your first microservice
npx nx g @nx/node:app user-service --directory=apps/user-service

# Generate a shared library
npx nx g @nx/js:lib shared-types --directory=libs/shared-types

# Start the development server
npm run nx serve user-service
```

## 🏗️ Project Structure

```
node-microservices/
├── apps/                       # Microservice applications
│   ├── api-gateway/           # API Gateway service
│   ├── user-service/          # User management service
│   ├── auth-service/          # Authentication service
│   └── notification-service/  # Notification service
├── libs/                      # Shared libraries
│   ├── shared-types/         # TypeScript interfaces and types
│   ├── shared-utils/         # Common utilities
│   ├── database/             # Database models and connections
│   └── messaging/            # Message queue integrations
├── tools/                     # Workspace tools and scripts
│   ├── generators/           # Custom Nx generators
│   └── scripts/              # Build and deployment scripts
├── docker/                    # Docker configurations
│   ├── development/          # Development Docker files
│   └── production/           # Production Docker files
├── .github/                   # GitHub Actions workflows
├── nx.json                    # Nx workspace configuration
├── tsconfig.base.json        # Base TypeScript configuration
├── package.json              # Node dependencies and scripts
├── docker-compose.yml        # Docker Compose configuration
└── .env.example              # Environment variables template
```

### Directory Explanations

- **Apps Directory**: Contains all microservice applications. Each app is independently deployable.
- **Libs Directory**: Shared code libraries that promote code reuse across services.
- **Tools Directory**: Custom workspace tools, generators, and utility scripts.
- **Docker Directory**: Containerization configurations for different environments.

## 🏛️ Architecture Overview

### Microservices Architecture Pattern

This workspace follows a microservices architecture with the following components:

1. **API Gateway**: Single entry point for all client requests
2. **Service Discovery**: Services can discover and communicate with each other
3. **Message Queue**: Asynchronous communication between services
4. **Shared Libraries**: Common code shared across services via Nx libraries
5. **Database per Service**: Each service owns its data and database

### Communication Patterns

- **Synchronous**: REST APIs for real-time communication
- **Asynchronous**: Message queues (RabbitMQ/Kafka) for event-driven architecture
- **GraphQL**: Optional GraphQL layer in API Gateway for flexible queries

## 💻 Development Guide

### Service Communication Examples

```typescript
// Synchronous REST call
import axios from 'axios';

export class UserService {
  async getUserById(id: string) {
    const response = await axios.get(`http://user-service:3000/users/${id}`);
    return response.data;
  }
}

// Asynchronous message publishing
import { MessageQueue } from '@libs/messaging';

export class OrderService {
  async createOrder(orderData: any) {
    // Save order to database
    const order = await this.orderRepository.save(orderData);
    
    // Publish event
    await MessageQueue.publish('order.created', order);
    
    return order;
  }
}
```

### Database Integration

Each microservice should have its own database. Example with Prisma:

```bash
# Install Prisma for a service
cd apps/user-service
npm install prisma @prisma/client
npx prisma init
```

## 📝 Common Commands

### Development

```bash
# Serve an application
npm run nx serve <app-name>

# Build an application
npm run nx build <app-name>

# Run tests for a project
npm run nx test <project-name>

# Run linting for a project
npm run nx lint <project-name>

# Run e2e tests
npm run nx e2e <app-name>
```

### Workspace Management

```bash
# View dependency graph
npm run graph

# Format code
npm run format

# Check formatting
npm run format:check

# Run affected commands (only on changed projects)
npm run affected:build
npm run affected:test
npm run affected:lint
```

## 🛠️ Creating New Projects

### Create a New Microservice

```bash
# Create a Node.js application
npx nx g @nx/node:app my-service --directory=apps/my-service

# Create an Express application
npx nx g @nx/express:app my-api --directory=apps/my-api
```

### Create a Shared Library

```bash
# Create a TypeScript library
npx nx g @nx/js:lib shared-utils --directory=libs/shared-utils

# Create a Node.js library
npx nx g @nx/node:lib shared-models --directory=libs/shared-models
```

## 🔧 Development Workflow

1. **Create a new feature branch:**
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **Make your changes and test locally:**
   ```bash
   npm run affected:test
   npm run affected:lint
   ```

3. **Build affected projects:**
   ```bash
   npm run affected:build
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

## 🔧 Environment Configuration

### Environment Variables

Create `.env` files for different environments:

```bash
.env                # Default/Development
.env.test          # Testing
.env.staging       # Staging
.env.production    # Production
```

Example `.env` file:
```env
# Application
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRATION=1d

# Message Queue
RABBITMQ_URL=amqp://localhost:5672

# External Services
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
```

### Configuration Management

Create a centralized configuration service:

```typescript
// libs/config/src/lib/config.service.ts
export class ConfigService {
  get(key: string): string {
    return process.env[key];
  }
  
  getNumber(key: string): number {
    return Number(this.get(key));
  }
  
  getBoolean(key: string): boolean {
    return this.get(key) === 'true';
  }
}
```

## 🧪 Testing Strategy

### Testing Levels

1. **Unit Tests** - Test individual functions and classes
2. **Integration Tests** - Test service interactions
3. **E2E Tests** - Test complete user flows
4. **Contract Tests** - Ensure API compatibility

### Running Tests

```bash
# Run all tests
npm run test

# Run tests for a specific project
npm run nx test my-app

# Run tests in watch mode
npm run nx test my-app --watch

# Run tests with coverage
npm run nx test my-app --coverage

# Run e2e tests
npm run nx e2e my-app-e2e
```

### Example Test

```typescript
// apps/user-service/src/users/users.service.spec.ts
describe('UsersService', () => {
  let service: UsersService;
  let repository: Repository<User>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: {
            find: jest.fn(),
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    repository = module.get<Repository<User>>(getRepositoryToken(User));
  });

  it('should create a user', async () => {
    const userData = { email: 'test@example.com', name: 'Test User' };
    jest.spyOn(repository, 'save').mockResolvedValue(userData as User);

    const result = await service.create(userData);
    expect(result).toEqual(userData);
  });
});
```

## 📦 Building for Production

```bash
# Build a specific application
npm run nx build my-app --configuration=production

# Build all applications
npm run nx run-many --target=build --all --configuration=production

# Build only affected applications
npm run affected:build --configuration=production
```

## 🚀 CI/CD Pipeline

### GitHub Actions Example

Create `.github/workflows/ci.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run affected lint
        run: npm run affected:lint -- --base=origin/main
      
      - name: Run affected tests
        run: npm run affected:test -- --base=origin/main --coverage
      
      - name: Build affected apps
        run: npm run affected:build -- --base=origin/main

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to production
        run: |
          # Add your deployment commands here
          echo "Deploying to production..."
```

## 📦 Deployment

### Docker Deployment

#### Multi-stage Dockerfile

Create an optimized Dockerfile for production:

```dockerfile
# Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Copy workspace files
COPY package*.json ./
COPY nx.json tsconfig.base.json ./
COPY apps/<service-name> ./apps/<service-name>
COPY libs ./libs

# Install dependencies and build
RUN npm ci
RUN npx nx build <service-name> --configuration=production

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy built application
COPY --from=builder /app/dist/apps/<service-name> .
COPY --from=builder /app/node_modules ./node_modules

# Run as non-root user
USER node

EXPOSE 3000

CMD ["node", "main.js"]
```

#### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  api-gateway:
    build:
      context: .
      dockerfile: apps/api-gateway/Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - postgres
      - redis

  user-service:
    build:
      context: .
      dockerfile: apps/user-service/Dockerfile
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${USER_DB_URL}
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: microservices
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Deployment

Example Kubernetes manifests:

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: your-registry/user-service:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

## 🔍 Analyzing Your Workspace

```bash
# View project graph in browser
npm run graph

# List all projects
npx nx list

# Show project details
npx nx show project my-app
```

## 📊 Monitoring & Logging

### Structured Logging

Implement centralized logging with Winston:

```typescript
// libs/logger/src/lib/logger.ts
import winston from 'winston';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: process.env.SERVICE_NAME },
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    }),
    new winston.transports.File({
      filename: 'error.log',
      level: 'error'
    })
  ]
});
```

### Health Checks

Implement health check endpoints:

```typescript
// apps/api-gateway/src/health/health.controller.ts
@Controller('health')
export class HealthController {
  @Get()
  healthCheck() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV,
    };
  }
  
  @Get('ready')
  async readinessCheck() {
    // Check database connection, external services, etc.
    const dbHealthy = await this.checkDatabase();
    const redisHealthy = await this.checkRedis();
    
    return {
      status: dbHealthy && redisHealthy ? 'ready' : 'not ready',
      services: {
        database: dbHealthy,
        redis: redisHealthy
      }
    };
  }
}
```

### Metrics Collection

Use Prometheus for metrics:

```typescript
// libs/metrics/src/lib/metrics.ts
import { register, Counter, Histogram } from 'prom-client';

export const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

export const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
```

## 🔧 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>
```

#### Nx Cache Issues
```bash
# Clear Nx cache
nx reset

# Run with skip-nx-cache
nx build my-app --skip-nx-cache
```

#### Dependency Issues
```bash
# Clean install
rm -rf node_modules package-lock.json
npm install

# Check for outdated packages
npm outdated
```

#### Build Failures
```bash
# Verbose build output
nx build my-app --verbose

# Check circular dependencies
nx graph
```

### Debugging

Enable debug mode for detailed logs:

```bash
# Debug Nx commands
NX_VERBOSE_LOGGING=true nx build my-app

# Debug Node.js application
node --inspect=0.0.0.0:9229 dist/apps/my-app/main.js
```

## 📚 Best Practices

### Code Organization

1. **Keep apps small and focused** - Each microservice should have a single responsibility
2. **Share code through libraries** - Extract common functionality into libs
3. **Use workspace generators** - Maintain consistency with custom generators
4. **Follow conventional commits** - Use conventional commit messages for better changelog generation
5. **Leverage caching** - Nx caches build outputs for faster subsequent builds

### Microservices Best Practices

1. **Database per Service** - Each service owns its database
2. **API Versioning** - Version your APIs to maintain backward compatibility
3. **Circuit Breakers** - Implement circuit breakers for fault tolerance
4. **Idempotency** - Ensure operations can be safely retried
5. **Event Sourcing** - Consider event sourcing for audit trails

### Security Guidelines

1. **Authentication** - Implement JWT-based authentication
2. **Authorization** - Use role-based access control (RBAC)
3. **Input Validation** - Validate all inputs at the API gateway
4. **Rate Limiting** - Implement rate limiting to prevent abuse
5. **Secrets Management** - Never commit secrets to version control

### Performance Optimization

1. **Caching** - Implement Redis caching for frequently accessed data
2. **Connection Pooling** - Use database connection pooling
3. **Async Operations** - Use async/await for non-blocking operations
4. **Load Balancing** - Distribute load across service instances
5. **Monitoring** - Monitor performance metrics continuously

## 🤝 Contributing

### Development Workflow

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/node-microservices.git
   cd node-microservices
   npm install
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make Changes**
   - Write clean, documented code
   - Add tests for new features
   - Update documentation as needed

4. **Test Your Changes**
   ```bash
   npm run affected:test
   npm run affected:lint
   npm run affected:build
   ```

5. **Commit with Conventional Commits**
   ```bash
   git commit -m "feat: add amazing feature"
   ```
   
   Commit types:
   - `feat`: New feature
   - `fix`: Bug fix
   - `docs`: Documentation changes
   - `style`: Code style changes
   - `refactor`: Code refactoring
   - `test`: Test additions or changes
   - `chore`: Maintenance tasks

6. **Push and Create PR**
   ```bash
   git push origin feature/amazing-feature
   ```

### Code Review Guidelines

- Ensure all tests pass
- Follow the established code style
- Add meaningful commit messages
- Update documentation for API changes
- Request review from maintainers

## 📚 Resources

### Documentation
- [Nx Documentation](https://nx.dev)
- [Microservices Patterns](https://microservices.io/patterns/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)

### Tools & Extensions
- [Nx Console for VS Code](https://marketplace.visualstudio.com/items?itemName=nrwl.angular-console)
- [Prisma VS Code Extension](https://marketplace.visualstudio.com/items?itemName=Prisma.prisma)
- [Docker Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
- [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)

### Community
- [Nx Discord](https://go.nx.dev/community)
- [Stack Overflow - Nx Tag](https://stackoverflow.com/questions/tagged/nx)
- [GitHub Discussions](https://github.com/nrwl/nx/discussions)

### Related Projects
- [NestJS](https://nestjs.com/) - Progressive Node.js framework
- [Express](https://expressjs.com/) - Fast, unopinionated web framework
- [Prisma](https://www.prisma.io/) - Next-generation ORM
- [Bull](https://github.com/OptimalBits/bull) - Redis-based queue

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to the Nx team for the amazing build system
- All contributors who help improve this project
- The open-source community for the tools and libraries used

## 📞 Support

For support and questions:
- 📧 Email: support@example.com
- 💬 Discord: [Join our server](https://discord.gg/example)
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/node-microservices/issues)
- 📖 Wiki: [Project Wiki](https://github.com/your-org/node-microservices/wiki)

---

<div align="center">
  <strong>Built with ❤️ using <a href="https://nx.dev">Nx</a></strong>
  <br>
  <sub>A Smart, Fast and Extensible Build System</sub>
</div> 