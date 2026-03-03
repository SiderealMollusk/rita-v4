# Platform Requirement 0002

## Topology And Lanes

The current platform is organized into clear lanes.

These lanes are not just hardware placements.
They are intended operational roles.

## Core Lanes

### `ops-brain`

`ops-brain` is the bootstrap and operations edge.

It currently carries:

- k3s control plane
- monitoring
- Flux bootstrap anchor
- ESO bootstrap anchor
- tolerated hand-rolled operator surfaces

It is not the intended home for general app workloads.

### `platform`

`platform` is the internal platform-services lane.

It is intended for:

- shared platform services
- cluster support services
- services that should stay off the operator laptop

It is not the default app lane.

### `workload`

`workload` is the default application lane.

It is intended for:

- user-facing workloads
- heavier off-the-shelf apps
- future custom applications

It is the preferred default home for general workloads.

### `main-vps`

`main-vps` is the public edge substrate.

It is primarily for:

- Pangolin
- public edge exposure
- public routing concerns

It is not the internal app platform.

## Current Cluster Node Roles

Validated node labels:

- `monitoring` -> `rita.role=ops-brain`
- `platform` -> `rita.role=platform`
- `workload` -> `rita.role=workload`

## Scheduling Intent

Current intent is:

- no general workloads on `ops-brain`
- no default spillover of general workloads onto `platform`
- `workload` is the intended default app lane

Hard taints may come later, but the strategic lane model is already fixed.
