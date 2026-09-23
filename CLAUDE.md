# Node Microservices

## Architecture

Nx monorepo with 4 services + 4 frontends in `apps/`:

- `auth-service` — NestJS 11, Keycloak + Passport JWT authentication
- `auth-frontend` — React 19, Keycloak JS SDK
- `stripe-service` — NestJS 11, Stripe payments
- `stripe-frontend` — React 19, Stripe Elements
- Each service has a matching `-e2e` app for Playwright end-to-end tests

## Stack

- **Backend**: NestJS 11, Passport (JWT + Keycloak strategies), class-validator, class-transformer, RxJS
- **Frontend**: React 19, Vite, React Router v6
- **Auth**: Keycloak (external IdP), JWT strategy in `auth/strategies/jwt.strategy.ts`, Keycloak strategy in `auth/strategies/keycloak.strategy.ts`
- **Payments**: Stripe server SDK + @stripe/react-stripe-js
- **Infra**: Docker Compose (Postgres 15, Redis 7, RabbitMQ, Kong Gateway, Prometheus, Grafana), Kubernetes (Kustomize overlays), Terraform (AWS EKS), Helm charts
- **Build**: Nx 21, Webpack (backend), Vite (frontend), SWC compiler

## Commands

```
nx serve <app>            # Run a service locally (e.g., nx serve auth-service)
nx test <app>             # Unit tests for a service
nx e2e <app>-e2e          # Playwright e2e tests
nx build <app>            # Build for production
nx affected:test          # Test only changed projects
nx affected:lint          # Lint only changed projects
nx affected -t typecheck  # Typecheck only changed projects
npm run format            # Prettier (single quotes)
make docker-up            # Start infra (Postgres, Redis, RabbitMQ, Kong, monitoring)
make docker-down          # Stop infra
make docker-build-prod    # Build production Docker images
```

## Project Structure

```
apps/
  auth-service/src/app/     # NestJS modules: auth/, common/, keycloak/, users/
  auth-frontend/src/        # React app with Keycloak integration
  stripe-service/src/app/   # NestJS: DTOs, health check, Stripe integration
  stripe-frontend/src/      # React app with Stripe Elements
docker/                     # Docker Compose overrides (keycloak, stripe), Kong, Grafana, Prometheus
k8s/                        # Kubernetes manifests (base/ + overlays/)
helm/                       # Helm charts
terraform/                  # AWS EKS infrastructure (modules/, environments/)
scripts/                    # deploy-k8s.sh, deploy-terraform.sh, setup-keycloak.sh, setup-kong.sh
```

## Conventions

- Prettier with single quotes, ESLint with Nx module boundary enforcement
- NestJS pattern: Controller → Service → Module, DTOs with class-validator decorators
- Guards in `common/guards/`, custom decorators in `common/decorators/`
- E2E tests: Playwright. Unit tests: Jest + Vitest
- Never edit `.env`, `package-lock.json`, or files in `dist/`, `node_modules/`

## CI/CD

GitHub Actions pipeline: format check → lint affected → test affected → build → Docker → deploy

- `develop` branch → deploys to dev (AWS EKS)
- `main` branch → deploys to production (AWS EKS) + Slack notification
- Security scanning: Trivy + npm audit
- Coverage: Codecov

## Working with this repo in Claude Code

- Trust facts: the repository is **public** (`github.com/milosCvetkovicDev/node-microservices`), so
  every push publishes. A push to `main` runs the production deploy job and one to `develop` the dev
  deploy job; open pull requests against `main` and never push to either branch directly.
- `.claude/settings.json` wires two hooks on `Edit|Write`. `.claude/hooks/protect-files.sh` blocks
  writes to `.env` and `.env.*` (except `.env.example`), `package-lock.json`, any `node_modules/`,
  and the root build outputs `dist/` and `coverage/`, case-insensitively. It exits 2, which is the
  only exit code that blocks a tool call, and it also blocks when `jq` is missing or the input is
  not valid JSON. `bash .claude/hooks/protect-files.test.sh` is its test table; run it after
  changing the guard. `.claude/hooks/format.sh` runs `eslint --fix` for TS/JS from the nearest
  `eslint.config.*`, then Prettier, on the written file only, and always exits 0.
- The hooks guard the file tools only; a shell command can still write those paths, and
  `npm install` legitimately rewrites `package-lock.json`.
- Personal permission rules belong in `.claude/settings.local.json`, which is gitignored.
- `.claude/agents/nestjs-reviewer.md` is a read-only reviewer for `apps/*-service/`.
