# VPS Ops Runbook Scripts

Run these in order. All scripts are no-arg and opinionated.

## Infrastructure bring-up (Ansible)
1. `01-ansible-ping.sh`
- Confirms inventory parsing and SSH+sudo connectivity.

2. `02-bootstrap-host.sh`
- Baseline host setup (packages, firewall, fail2ban).

3. `03-install-k3s.sh`
- Installs single-node k3s control plane on VPS.

4. `04-install-eso.sh`
- Installs External Secrets Operator via Helm.

5. `05-apply-secret-bridge.sh`
- Applies SecretStore + ExternalSecret and verifies decoded test value.

## Pangolin workflows (after infra is healthy)
6. `06-pangolin-preflight.sh`
- Verifies k8s/ESO/secret preconditions before Pangolin deploy.

7. `07-pangolin-deploy.sh`
- Deploys Pangolin in attached mode.

8. `08-pangolin-verify.sh`
- Verifies post-deploy status.

9. `09-pangolin-rollback.sh`
- Executes rollback (`pangolin down`) when needed.

## 1Password prerequisites
- `OP_SERVICE_ACCOUNT_TOKEN` must be present in the shell running script `05`.
- Vault referenced by `op_vault_id` (in `ops/ansible/group_vars/vps.yml`) must contain:
  - item `test`
  - field `foo`
  - expected value `bar`
- SSH admin key for VPS access should be stored in your user vault (separate from app secrets when possible).
