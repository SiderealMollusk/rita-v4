# 0060 - VPS Ansible Bootstrap and Runbook Refactor
Status: 🟡 IN PROGRESS
Date: 2026-02-27
Scope: Move from local-only validation to VPS-first Kubernetes + ESO bring-up using numbered no-arg runbook scripts.

## Context from 0050
- `0050` validated the secret format and local bridge behavior (`test/foo` -> `bar`) on local k8s.
- Current phase moves that same secret bridge model to a real VPS cluster.

## What is complete
- SSH access path stabilized:
  - New SSH key created in 1Password and installed on VPS.
  - Non-root sudo user (`virgil`) verified for remote ops.
- Ansible connectivity confirmed:
  - `scripts/2-ops/vps/01-ansible-ping.sh` returns success (`pong`).
- k3s control plane installed on VPS:
  - `scripts/2-ops/vps/03-install-k3s.sh` completed successfully.
- ESO install path fixed and validated:
  - Initial failure was kubeconfig context (`localhost:8080`).
  - Playbooks updated to force `KUBECONFIG=/etc/rancher/k3s/k3s.yaml`.
  - `scripts/2-ops/vps/04-install-eso.sh` then succeeded.

## Script architecture changes
- `scripts/2-ops/vps` was refactored into an ordered no-arg runbook:
  1. `01-ansible-ping.sh`
  2. `02-bootstrap-host.sh`
  3. `03-install-k3s.sh`
  4. `04-install-eso.sh`
  5. `05-apply-secret-bridge.sh`
  6. `06-pangolin-preflight.sh`
  7. `07-pangolin-deploy.sh`
  8. `08-pangolin-verify.sh`
  9. `09-pangolin-rollback.sh`
- Ansible playbooks and templates added:
  - `ops/ansible/playbooks/10-bootstrap-host.yml`
  - `ops/ansible/playbooks/20-install-k3s.yml`
  - `ops/ansible/playbooks/30-install-eso.yml`
  - `ops/ansible/playbooks/40-apply-secret-bridge.yml`
  - `ops/ansible/templates/0010-onepassword-store.yaml.j2`
  - `ops/ansible/templates/0020-test-secret.yaml.j2`

## DRY utility and guardrails added
- Shared helper: `scripts/lib/runbook.sh`
  - no-arg enforcement
  - repo-root detection (host vs devcontainer paths)
  - command/env var guards
- `05-apply-secret-bridge.sh` now:
  - hard-fails if `OP_SERVICE_ACCOUNT_TOKEN` is missing,
  - sources `.labrc` and uses `OP_VAULT_ID` as canonical vault ID,
  - reminds to run `source scripts/1-session/01-load-variables.sh` when context vars are unset.

## Issue encountered and fixed
- `05-apply-secret-bridge.sh` failed with:
  - `'eso_namespace' is undefined`
- Playbook fix:
  - `40-apply-secret-bridge.yml` now sets safe defaults in `pre_tasks` for required vars when group vars are not loaded.

## Current state
- VPS cluster exists and is reachable.
- k3s and ESO are installed.
- Secret bridge apply step was blocked by undefined vars, and that fix is now in place.

## Next command (resume point)
```bash
scripts/2-ops/vps/05-apply-secret-bridge.sh
```

## Expected result
- SecretStore `onepassword-store` Ready=True
- ExternalSecret `lab-test-sync` Ready=True
- decoded value from `rita-test-k8s-secret` equals `bar`

## 2026-02-27 Late Update
- Resume command has been executed successfully:
  - `scripts/2-ops/vps/05-apply-secret-bridge.sh` now completes and asserts decoded `bar`.
- VPS reset/reseed flow was formalized with:
  - `scripts/0-local-setup/03-vps/01-seed-ssh-admin-from-op.sh`
- VPS runbook structure was updated to reflect infra-first then Pangolin actions.
- See newest entry: `0070-vps-reset-and-reseed.md`.
