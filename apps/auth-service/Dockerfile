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
COPY apps/auth-service ./apps/auth-service

# Build the application
RUN npm run build:auth-service

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built application (includes generated package.json with production deps)
COPY --from=builder /app/dist/apps/auth-service ./

# Copy package-lock.json for npm ci (required for deterministic installs)
COPY --from=builder /app/package-lock.json ./

# Install only production dependencies using the generated package.json
RUN npm ci --omit=dev --legacy-peer-deps && npm cache clean --force

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

# Expose port
EXPOSE 3334

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3334/api/auth/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

# Start the application
CMD ["node", "main.js"] 