# 0070 - VPS Reset, SSH Reseed, and Infra Revalidation
Status: 🟡 IN PROGRESS
Date: 2026-02-27
Scope: Validate wipe/reseed process and re-establish VPS k3s + ESO + secret bridge using current runbook.

## What happened
- VPS was reset (fresh host state).
- SSH trust/key bootstrap needed to be re-established.
- 1Password mode confusion surfaced (service account vs user vault access).
- Host key mismatch surfaced (expected after wipe).

## Fixes and improvements made
- Added generic host-side reseed script:
  - `scripts/0-local-setup/03-vps/01-seed-ssh-admin-from-op.sh`
- Script now:
  - aborts in devcontainer,
  - aborts if `OP_SERVICE_ACCOUNT_TOKEN` is set,
  - removes stale `known_hosts` entries for target host,
  - uses `StrictHostKeyChecking=accept-new`,
  - installs key for root + admin user and configures passwordless sudo.

## VPS infra status after reseed
- `01-ansible-ping.sh`: success
- `03-install-k3s.sh`: success
- `04-install-eso.sh`: success
- `05-apply-secret-bridge.sh`: success
  - SecretStore Ready=True
  - ExternalSecret Ready=True
  - decoded secret assertion (`bar`) passed

## Current blocker
- `07-pangolin-deploy.sh` currently fails on VPS with:
  - `pangolin: not found`
- Meaning: Pangolin CLI/server components are not yet installed on VPS host.

## Current interpretation
- Kubernetes control plane exists on VPS (single-node k3s).
- ESO + 1Password bridge are functioning.
- Next phase is Pangolin component installation and auth/config, not cluster/secrets plumbing.

## Next commands
```bash
# Install pangolin CLI on VPS host
ansible -i /workspaces/rita-v4/ops/ansible/inventory/vps.ini vps -b -m shell -a 'curl -fsSL https://static.pangolin.net/get-cli.sh | bash'

# Verify install
ansible -i /workspaces/rita-v4/ops/ansible/inventory/vps.ini vps -b -m shell -a 'pangolin --version'

# Retry deploy
scripts/2-ops/vps/07-pangolin-deploy.sh
```
