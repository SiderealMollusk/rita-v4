# Access Policy

This doc explains the login model and where to verify it.
It is intentionally thin; inventories and setup scripts remain primary.

For the most recent validated state, use the latest relevant progress note in `docs/progress_log/`.

## Principles
1. Day-to-day SSH should use the non-root admin user `virgil`.
2. Root SSH is bootstrap/break-glass only.
3. SSH keys come from 1Password.
4. Repo automation should assume `virgil` + sudo, not permanent root login.
5. Public/operator-facing service access should prefer Pangolin-managed routes.
6. Privileged operator mutations should stay on the Mac host when the auth/session lives there.

## Machine Login Pattern
### VPS
1. SSH user: `virgil`
2. Root: bootstrap/break-glass only
3. Inventory: `ops/ansible/inventory/vps.ini`
4. Bootstrap/reseed helpers:
- `scripts/0-local-setup/03-vps/`
- `docs/reset-vps.md`

### Ops-Brain
1. SSH user: `virgil`
2. `virgil` is expected to have sudo
3. Inventory: `ops/ansible/inventory/ops-brain.ini`
4. Bootstrap helpers:
- `scripts/0-local-setup/01-lan/`
- `scripts/2-ops/ops-brain/`

## Service Access Pattern
1. Public/operator-facing routes:
- `ops/network/routes.yml`
2. Pangolin semantics and guardrails:
- `docs/pangolin/0001-deploy-model.md`
3. Monitoring/operator services are intended to be exposed intentionally, not by ad-hoc direct host access.
4. Cluster-local service addresses are valid Pangolin targets only when they have been verified from the Newt/site perspective.

## Verify
1. Confirm host/user details from `ops/ansible/inventory/*.ini`
2. Confirm public routes from `ops/network/routes.yml`
3. Confirm current runbooks from `scripts/2-ops/`
4. Confirm recent validated state from `docs/progress_log/`
