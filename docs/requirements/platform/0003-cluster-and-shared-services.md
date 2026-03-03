# Platform Requirement 0003

## Cluster And Shared Services

The current internal cluster is a shared substrate.

It should carry a small number of clear platform primitives rather than a pile of unrelated stateful services.

## Current Shared Primitives

### k3s

Internal cluster substrate for platform and workload scheduling.

### Flux

GitOps controller for in-cluster desired state.

### External Secrets Operator

Secret substrate for app-level secret material.

### `platform-postgres`

Shared Postgres service for platform and app use cases that naturally converge on Postgres.

It is a shared primitive, not an app-local database.

### Nextcloud

Current collaboration front office.

It is a major application, but also an important shared workspace surface for future product work.

## Intentional Non-Primitives

These are intentionally not treated as universal platform primitives right now:

- one single database technology for every app
- universal auth/IdP
- universal app registry/forge for all workflows
- one single platform shell for every custom app
