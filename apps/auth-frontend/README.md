# Auth Frontend

This is the authentication frontend for the Node.js microservices application built with React, TypeScript, and Tailwind CSS.

## Features

- User registration and login
- Integration with Keycloak for SSO
- JWT token management with HTTP-only cookies
- Protected routes with authentication guards
- Responsive UI with Tailwind CSS
- Automatic token refresh

## Environment Variables

The following environment variables can be configured:

- `VITE_KEYCLOAK_URL` - Keycloak server URL (default: http://localhost:8180)
- `VITE_KEYCLOAK_REALM` - Keycloak realm name (default: microservices)
- `VITE_KEYCLOAK_CLIENT_ID` - Keycloak client ID (default: auth-frontend)
- `VITE_AUTH_SERVICE_URL` - Auth service API URL (default: http://localhost:3334)

## Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the development server:
   ```bash
   nx serve auth-frontend
   ```

3. The application will be available at http://localhost:4200

## Building for Production

```bash
nx build auth-frontend
```

The build artifacts will be stored in the `dist/apps/auth-frontend` directory.

## Running with Docker

1. Build the Docker image:
   ```bash
   docker build -f apps/auth-frontend/Dockerfile -t auth-frontend .
   ```

2. Run the container:
   ```bash
   docker run -p 4200:80 auth-frontend
   ```

## Features Overview

### Authentication Flow

1. **Registration**: Users can create new accounts with username, email, and password
2. **Login**: Users can login with username/password or use Keycloak SSO
3. **Session Management**: JWT tokens are stored in HTTP-only cookies
4. **Auto Refresh**: Tokens are automatically refreshed before expiration

### Protected Routes

- `/dashboard` - User dashboard (requires authentication)
- `/login` - Login page (redirects to dashboard if authenticated)
- `/register` - Registration page

### Security Features

- HTTP-only cookies prevent XSS attacks
- CSRF protection with SameSite cookies
- Automatic token refresh
- Secure communication with auth service

## Architecture

The frontend uses:
- **React** with TypeScript for type safety
- **React Router** for client-side routing
- **Axios** for HTTP requests with interceptors
- **Context API** for state management
- **Tailwind CSS** for styling
- **Nginx** for production deployment 