# API Gateway Documentation

The API Gateway serves as the single entry point for all client requests to the microservices architecture. It handles routing, authentication, rate limiting, and request/response transformation.

## 🌐 Base URL

```
Development: http://localhost:3000
Staging: https://api-staging.example.com
Production: https://api.example.com
```

## 🔑 Authentication

All authenticated endpoints require a JWT token in the Authorization header:

```http
Authorization: Bearer <jwt-token>
```

### Obtaining a Token

```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 3600
  }
}
```

## 📋 Available Routes

### Health Check

```http
GET /health
```

Check the health status of the API Gateway.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0",
  "services": {
    "user-service": "healthy",
    "auth-service": "healthy",
    "notification-service": "healthy"
  }
}
```

### Authentication Routes

#### Register

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John Doe"
}
```

**Validation Rules:**
- Email: Valid email format
- Password: Min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
- Name: Required, min 2 chars

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "email": "user@example.com",
      "name": "John Doe",
      "createdAt": "2024-01-15T10:30:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

#### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "email": "user@example.com",
      "name": "John Doe"
    }
  }
}
```

#### Refresh Token

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 3600
  }
}
```

#### Logout

```http
POST /api/auth/logout
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### User Routes

#### Get Current User

```http
GET /api/users/me
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "name": "John Doe",
    "profile": {
      "bio": "Software Developer",
      "avatar": "https://example.com/avatar.jpg",
      "preferences": {
        "notifications": true,
        "theme": "dark"
      }
    }
  }
}
```

#### Update Profile

```http
PUT /api/users/me
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Jane Doe",
  "profile": {
    "bio": "Full Stack Developer",
    "preferences": {
      "notifications": false
    }
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "name": "Jane Doe",
    "profile": {
      "bio": "Full Stack Developer",
      "avatar": "https://example.com/avatar.jpg",
      "preferences": {
        "notifications": false,
        "theme": "dark"
      }
    }
  }
}
```

#### List Users (Admin Only)

```http
GET /api/users?page=1&limit=10&search=john
Authorization: Bearer <admin-token>
```

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10, max: 100)
- `search`: Search by name or email
- `sortBy`: Sort field (name, email, createdAt)
- `sortOrder`: asc or desc

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "email": "user@example.com",
        "name": "John Doe",
        "role": "user",
        "createdAt": "2024-01-15T10:30:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 100,
      "pages": 10
    }
  }
}
```

### Notification Routes

#### Send Notification

```http
POST /api/notifications/send
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "email",
  "recipient": "user@example.com",
  "template": "welcome",
  "data": {
    "name": "John Doe",
    "activationLink": "https://example.com/activate/123"
  }
}
```

**Notification Types:**
- `email`: Email notification
- `sms`: SMS notification
- `push`: Push notification
- `inapp`: In-app notification

**Response:**
```json
{
  "success": true,
  "data": {
    "notificationId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "queued",
    "scheduledAt": "2024-01-15T10:30:00.000Z"
  }
}
```

#### Get Notification Status

```http
GET /api/notifications/{notificationId}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "email",
    "status": "delivered",
    "recipient": "user@example.com",
    "sentAt": "2024-01-15T10:31:00.000Z",
    "metadata": {
      "messageId": "0000014a-5d5a-5e8f-ac72-b12c9f7f5d5a",
      "opens": 1,
      "clicks": 0
    }
  }
}
```

## 🚦 Rate Limiting

The API Gateway implements rate limiting to prevent abuse:

### Default Limits

- **Anonymous users**: 100 requests per 15 minutes
- **Authenticated users**: 1000 requests per 15 minutes
- **Admin users**: 10000 requests per 15 minutes

### Rate Limit Headers

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642248000
```

### Rate Limit Exceeded Response

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests, please try again later",
    "retryAfter": 900
  }
}
```

## 🔍 Request ID Tracking

Every request is assigned a unique ID for tracking:

```http
X-Request-ID: 550e8400-e29b-41d4-a716-446655440000
```

Include this ID when reporting issues for faster debugging.

## ❌ Error Responses

### Standard Error Format

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "Additional error context"
    }
  },
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

### Validation Error Example

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "email": "Invalid email format",
      "password": "Password must be at least 8 characters"
    }
  }
}
```

## 🔄 API Versioning

The API supports versioning through URL path:

```
/api/v1/users  (current)
/api/v2/users  (future)
```

### Version Deprecation

Deprecated versions will include a warning header:

```http
X-API-Deprecation-Warning: Version 1 is deprecated. Please migrate to version 2.
X-API-Deprecation-Date: 2024-12-31
```

## 🌍 CORS Configuration

### Allowed Origins

- Development: `http://localhost:*`
- Staging: `https://*.staging.example.com`
- Production: `https://example.com`, `https://www.example.com`

### Allowed Methods

```
GET, POST, PUT, DELETE, PATCH, OPTIONS
```

### Allowed Headers

```
Authorization, Content-Type, X-Request-ID
```

## 📊 Metrics Endpoint

```http
GET /metrics
```

Returns Prometheus-formatted metrics:

```
# HELP http_request_duration_seconds HTTP request latencies
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",route="/api/users",status="200",le="0.1"} 123
http_request_duration_seconds_bucket{method="GET",route="/api/users",status="200",le="0.5"} 456

# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/api/users",status="200"} 1234
```

## 🧪 Testing with cURL

### Basic Examples

```bash
# Health check
curl http://localhost:3000/health

# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","name":"Test User"}'

# Login and save token
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!"}' \
  | jq -r '.data.token')

# Get profile
curl http://localhost:3000/api/users/me \
  -H "Authorization: Bearer $TOKEN"
```

## 📚 SDK Examples

### JavaScript/TypeScript

```typescript
import axios from 'axios';

class APIClient {
  private token: string | null = null;
  private baseURL = 'http://localhost:3000';

  async login(email: string, password: string) {
    const response = await axios.post(`${this.baseURL}/api/auth/login`, {
      email,
      password
    });
    this.token = response.data.data.token;
    return response.data;
  }

  async getProfile() {
    return axios.get(`${this.baseURL}/api/users/me`, {
      headers: {
        Authorization: `Bearer ${this.token}`
      }
    });
  }
}
```

### Python

```python
import requests

class APIClient:
    def __init__(self, base_url='http://localhost:3000'):
        self.base_url = base_url
        self.token = None
    
    def login(self, email, password):
        response = requests.post(
            f'{self.base_url}/api/auth/login',
            json={'email': email, 'password': password}
        )
        data = response.json()
        self.token = data['data']['token']
        return data
    
    def get_profile(self):
        return requests.get(
            f'{self.base_url}/api/users/me',
            headers={'Authorization': f'Bearer {self.token}'}
        ).json()
```

## 🔗 Postman Collection

Import our Postman collection for easy API testing:

[Download Postman Collection](../postman/api-gateway-collection.json)

## 📖 OpenAPI Specification

View the full OpenAPI 3.0 specification:

[OpenAPI Spec](http://localhost:3000/api-docs)

---

**Last Updated**: January 2024
**API Version**: 1.0.0
**Contact**: api-support@example.com 