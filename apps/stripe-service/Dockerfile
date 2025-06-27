# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /repo

# Copy root files
COPY package.json package-lock.json ./
COPY nx.json tsconfig.base.json ./
COPY apps/stripe-service ./apps/stripe-service
COPY libs ./libs

# Install dependencies and build only the service
RUN npm install --frozen-lockfile --legacy-peer-deps && npx nx build stripe-service

# Stage 2: Run
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /repo/dist/apps/stripe-service ./dist
COPY --from=builder /repo/package*.json ./
COPY --from=builder /repo/node_modules ./node_modules
COPY --from=builder /repo/apps/stripe-service/.env .env
EXPOSE 3333
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:3333/liveness || exit 1
CMD ["node", "dist/main.js"] 