# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /repo

COPY package.json package-lock.json ./
COPY nx.json tsconfig.base.json ./
COPY apps/stripe-frontend ./apps/stripe-frontend

RUN npm install --frozen-lockfile --legacy-peer-deps && npx nx build stripe-frontend

# Stage 2: Serve
FROM nginx:alpine
COPY --from=builder /repo/dist/apps/stripe-frontend /usr/share/nginx/html
COPY ./apps/stripe-frontend/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"] 