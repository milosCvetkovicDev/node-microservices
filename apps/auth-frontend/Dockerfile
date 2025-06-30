# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Install dependencies with legacy peer deps to handle version conflicts
RUN npm ci --legacy-peer-deps

# Copy source code
COPY apps/auth-frontend ./apps/auth-frontend
COPY libs ./libs

# Build the application
RUN npm run build:auth-frontend

# Production stage
FROM nginx:alpine

# Copy built application
COPY --from=builder /app/dist/apps/auth-frontend /usr/share/nginx/html

# Copy nginx configuration
COPY apps/auth-frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"] 