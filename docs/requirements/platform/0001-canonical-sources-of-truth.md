# Platform Requirement 0001

## Canonical Sources Of Truth

This document defines where truth lives for the current platform.

The goal is to keep repo-managed facts stable and avoid hidden operator memory or ad hoc shell state.

## Core Rule

Every stable platform fact should have one canonical home.

Wrappers and runbooks may consume or render that truth, but should not become competing sources of truth.

## Canonical Locations

### 1. Inventory: Reachability And Identity

`ops/ansible/inventory/`

Use inventory for:

- inventory hostnames
- `ansible_host`
- `ansible_user`
- SSH port
- host grouping

If the question is "how do I reach this machine?", inventory is the canonical answer.

### 2. `host_vars`: Host-Specific Durable Facts

`ops/ansible/host_vars/`

Use host vars for facts about one exact host or substrate:

- physical location
- hardware class
- Proxmox VMIDs and template IDs
- LAN intent
- gateway/CIDR intent
- site-specific host facts

If the question is "what is true about this exact machine?", `host_vars` is the canonical answer.

### 3. `group_vars`: Shared Lane Or Role Defaults

`ops/ansible/group_vars/`

Use group vars for shared defaults across a role or lane:

- k3s defaults
- firewall allowlists
- platform lane defaults
- workload lane defaults
- shared service config

If the question is "what is true about this class of machines?", `group_vars` is the canonical answer.

### 4. GitOps Tree: Desired In-Cluster State

`ops/gitops/`

Use the GitOps tree for:

- namespaces
- Helm repositories
- Helm releases
- manifests that should reconcile onto the cluster

If the question is "what should exist in the cluster?", the GitOps tree is the canonical answer.

### 5. Routes Catalog: Public Exposure Intent

`ops/network/routes.yml`

Use the routes catalog for:

- public hostnames
- exposure type
- intended backend lane

If the question is "how is this app supposed to be exposed?", the routes catalog is the canonical answer.

### 6. `.labrc`: Operator-Local Non-Secret Config

`.labrc`

Use `.labrc` for local operator config that should not be hardcoded into repo-managed manifests:

- kubeconfig path
- vault ID
- other local, non-secret operator defaults

Wrappers should prefer `.labrc` over repeated ad hoc exports.

### 7. 1Password: Secrets

1Password is the canonical home for secrets:

- passwords
- API tokens
- bootstrap secrets
- DB credentials

Stable item and field names should be reflected in repo docs and manifests, but the values live in 1Password.

## Non-Canonical Surfaces

These may be useful, but are not canonical truth:

- remembered shell exports
- dashboard state
- hand-edited live cluster objects
- one-off CLI inspection output
- ad hoc Pangolin settings not captured in docs/progress

## Freshness Anchors

Current architectural context:

- [`docs/progress_log/0480-ard-platform-and-product-sketches-added.md`](/Users/virgil/Dev/rita-v4/docs/progress_log/0480-ard-platform-and-product-sketches-added.md)
- [`docs/progress_log/0490-platform-ard-refactored-into-numbered-sots.md`](/Users/virgil/Dev/rita-v4/docs/progress_log/0490-platform-ard-refactored-into-numbered-sots.md)
