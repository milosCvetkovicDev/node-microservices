# Kong Gateway Implementation

## Overview

Kong Gateway has been implemented as the API gateway for the microservices architecture. It provides:

- **Centralized API Management**: All microservice APIs are routed through Kong
- **Authentication & Authorization**: Multiple auth methods (API Key, JWT, Basic Auth)
- **Rate Limiting**: Configurable rate limits per consumer and globally
- **Monitoring**: Prometheus metrics and request logging
- **Load Balancing**: Built-in load balancing across service instances
- **Plugin Ecosystem**: Extensible with 100+ plugins

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────┐
│   Kong Gateway          │
│   (Port 8000/8443)      │
├─────────────────────────┤
│ • Routing               │
│ • Authentication        │
│ • Rate Limiting         │
│ • CORS                  │
│ • Logging & Metrics     │
└──────┬──────────────────┘
       │
       ├────────────────┬────────────────┬─────────────────┐
       ▼                ▼                ▼                 ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ User Service │ │ Auth Service │ │ Notification │ │   Other      │
│ (Port 3001)  │ │ (Port 3002)  │ │   Service    │ │  Services    │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

## Local Development Setup

### 1. Start Kong with Docker Compose

```bash
# Start all services including Kong
docker-compose up -d

# Check Kong is running
curl http://localhost:8000
```

### 2. Access Kong Services

- **Kong Proxy**: http://localhost:8000 (API Gateway endpoint)
- **Kong Admin API**: http://localhost:8001 (Configuration API)
- **Kong Manager GUI**: http://localhost:8002 (Web UI)
- **Konga UI**: http://localhost:1337 (Alternative admin UI)

### 3. Verify Kong Setup

```bash
# Check Kong status
curl http://localhost:8001/status

# List services
curl http://localhost:8001/services

# List routes
curl http://localhost:8001/routes
```

## API Routes

All microservice APIs are accessed through Kong Gateway:

| Service | Original Port | Kong Route | Example |
|---------|--------------|------------|---------|
| User Service | 3001 | `/api/users` | `GET http://localhost:8000/api/users` |
| Auth Service | 3002 | `/api/auth` | `POST http://localhost:8000/api/auth/login` |
| Notification Service | 3003 | `/api/notifications` | `GET http://localhost:8000/api/notifications` |
| Health Check | - | `/health` | `GET http://localhost:8000/health` |

## Authentication

### 1. API Key Authentication

```bash
# Create a consumer
curl -X POST http://localhost:8001/consumers \
  -d "username=myapp"

# Create API key for consumer
curl -X POST http://localhost:8001/consumers/myapp/key-auth \
  -d "key=my-api-key"

# Use API key in requests
curl http://localhost:8000/api/users \
  -H "apikey: my-api-key"
```

### 2. JWT Authentication

```bash
# Create JWT credentials for a consumer
curl -X POST http://localhost:8001/consumers/myapp/jwt \
  -d "algorithm=HS256" \
  -d "key=myapp-key" \
  -d "secret=my-secret-key"

# Generate JWT token and use in requests
curl http://localhost:8000/api/users \
  -H "Authorization: Bearer <jwt-token>"
```

## Rate Limiting

Rate limits are configured per consumer:

- **Admin users**: 1000 requests/minute, 10000 requests/hour
- **Service accounts**: 5000 requests/minute, 50000 requests/hour
- **Default**: 100 requests/minute, 10000 requests/hour

Check rate limit headers in responses:
```
X-RateLimit-Limit-Minute: 1000
X-RateLimit-Remaining-Minute: 999
X-RateLimit-Limit-Hour: 10000
X-RateLimit-Remaining-Hour: 9999
```

## Monitoring

### Prometheus Metrics

Kong exposes metrics at: `http://localhost:8001/metrics`

Key metrics:
- `kong_http_requests_total`: Total HTTP requests
- `kong_http_latency`: Request latency histogram
- `kong_bandwidth_bytes`: Bandwidth usage
- `kong_upstream_target_health`: Upstream service health

### Request Logging

All requests are logged with:
- Request/response headers
- Status codes
- Latency
- Client IP
- User agent

## Kong Admin API Examples

### Add a New Service

```bash
curl -X POST http://localhost:8001/services \
  -d "name=new-service" \
  -d "url=http://new-service:3004"
```

### Add a Route to Service

```bash
curl -X POST http://localhost:8001/services/new-service/routes \
  -d "paths[]=/api/new" \
  -d "methods[]=GET" \
  -d "methods[]=POST"
```

### Enable Plugin on Service

```bash
# Enable rate limiting
curl -X POST http://localhost:8001/services/new-service/plugins \
  -d "name=rate-limiting" \
  -d "config.minute=100" \
  -d "config.hour=10000"

# Enable CORS
curl -X POST http://localhost:8001/services/new-service/plugins \
  -d "name=cors" \
  -d "config.origins=*" \
  -d "config.methods=GET,POST,PUT,DELETE"
```

## Kubernetes Deployment

### Deploy Kong to Kubernetes

```bash
# Deploy Kong
kubectl apply -k k8s/base/

# Wait for Kong to be ready
kubectl wait --for=condition=ready pod -l app=kong -n microservices --timeout=300s

# Check Kong pods
kubectl get pods -n microservices -l app=kong

# Access Kong Admin API (port-forward)
kubectl port-forward svc/kong-admin 8001:8001 -n microservices
```

### Configure Services in Kubernetes

Kong automatically discovers services in Kubernetes. Services are configured via:

1. **ConfigMap**: `kong-config` contains declarative configuration
2. **Annotations**: Services can be annotated for Kong ingress
3. **Admin API**: Dynamic configuration via Kong Admin API

## Troubleshooting

### Check Kong Logs

```bash
# Docker
docker-compose logs -f kong

# Kubernetes
kubectl logs -n microservices -l app=kong -f
```

### Common Issues

1. **Service Unreachable**
   ```bash
   # Check service registration
   curl http://localhost:8001/services/user-service
   
   # Check upstream targets
   curl http://localhost:8001/upstreams/user-service/targets
   ```

2. **Authentication Failures**
   ```bash
   # Check consumer exists
   curl http://localhost:8001/consumers/myapp
   
   # Check credentials
   curl http://localhost:8001/consumers/myapp/key-auth
   ```

3. **Rate Limit Hit**
   - Check `X-RateLimit-Remaining-*` headers
   - Increase limits via Admin API or configuration

## Security Best Practices

1. **Secure Admin API**: Never expose port 8001 publicly
2. **Use HTTPS**: Enable SSL/TLS on port 8443
3. **Strong Secrets**: Change all default passwords
4. **Network Policies**: Restrict inter-service communication
5. **Regular Updates**: Keep Kong and plugins updated

## Performance Tuning

1. **Worker Processes**: Set based on CPU cores
2. **Database Connections**: Pool size optimization
3. **Caching**: Enable proxy caching plugin
4. **Compression**: Enable gzip plugin
5. **Keep-Alive**: Configure upstream keep-alive

## References

- [Kong Documentation](https://docs.konghq.com/)
- [Kong Plugin Hub](https://docs.konghq.com/hub/)
- [Kong Admin API Reference](https://docs.konghq.com/gateway/latest/admin-api/)
- [Kong Best Practices](https://docs.konghq.com/gateway/latest/production/)