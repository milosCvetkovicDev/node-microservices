# node-microservices

Nx monorepo reference for running NestJS + React verticals behind Kong on Kubernetes, with Terraform-provisioned infrastructure and an Nx-affected CI pipeline.

## What's here

Two working verticals, each a NestJS service with a Vite/React front end and its own e2e project:

- **Auth** — Keycloak-backed authentication: a NestJS service wrapping Keycloak (register / login / token refresh, JWT strategy, guards, current-user decorator) and a React front end with protected routes.
- **Payments** — Stripe payment intents: a NestJS service exposing a payment-intent API and a React checkout front end using Stripe Elements.

Around them, the platform pieces:

| Piece | What it shows |
|---|---|
| `docker/` | Local stack: Keycloak, Kong (declarative config), Prometheus + Grafana |
| `k8s/` | Kustomize base + development/production overlays — Deployments, HPAs, network policies, RBAC, Kong |
| `helm/` | The same deployment expressed as a Helm chart |
| `terraform/` | Modules + per-environment configs for provisioning the cluster infrastructure |
| `.github/workflows/ci-cd.yml` | Lint + test against real Postgres/Redis service containers, Nx affected-based |

## Honest scope

This is a reference architecture I keep as a runnable home for platform patterns — not a product. Parts of the Kubernetes manifests and Makefile still describe an earlier four-service target layout (api-gateway, user-service, notification-service) that the app tree has since moved away from. Treat `apps/` as the source of truth for what runs, and the infra directories as worked examples of the patterns.

## Run it

```bash
npm install

# local infrastructure (Keycloak, Kong, Prometheus/Grafana)
make docker-up

# serve a vertical
npx nx serve auth-service
npx nx serve auth-frontend

# tests / lint across affected projects
npx nx affected -t test lint
```

Environment variables are documented per app — copy the `.env.example` files and fill in your own values. Nothing in this repo assumes real credentials.

## License

MIT
