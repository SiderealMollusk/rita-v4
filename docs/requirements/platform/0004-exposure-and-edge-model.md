# Platform Requirement 0004

## Exposure And Edge Model

The public edge is a distinct concern from internal service architecture.

## Core Rule

Pangolin handles exposure.

Internal services should remain internally shaped first, then be exposed deliberately through the edge.

## Current Exposure Shape

### DNS

Public hostnames point at the Pangolin edge.

### Pangolin

Pangolin is the public resource and access layer.

### Internal Backend

The edge routes to internal services through the connected site model.

Validated example:

- `app.virgil.info`
- Pangolin resource via `ops-brain`
- backend target `nextcloud.workload.svc.cluster.local:8080`

## Important Validated Behavior

For the current working Nextcloud path, Pangolin backend SSL remains enabled in the live validated configuration.

That observed working behavior is canonical over generic reverse-proxy intuition.
