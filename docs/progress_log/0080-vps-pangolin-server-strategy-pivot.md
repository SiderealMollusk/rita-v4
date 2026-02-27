# 0080 - VPS Pangolin-Server Strategy Pivot
Date: 2026-02-27  
Status: ✅ IN PROGRESS (strategy pivot completed, deploy flow retooled)

## Context
After validating upstream sources, `charts.fossorial.io` currently lists `fossorial/newt` only.  
`fossorial/pangolin` is not discoverable via `helm search repo` as of 2026-02-27.

Because of this, VPS deployment strategy was changed from k8s/ESO/Helm to direct pangolin-server installer/runtime flow.

## What Changed
1. Replaced VPS runbook pipeline:
- old: k3s + ESO + secret bridge + pangolin CLI/helm assumptions
- new: host bootstrap -> docker runtime -> pangolin installer -> setup token capture -> verify

2. Updated `scripts/2-ops/vps`:
- Added:
  - `03-install-runtime.sh`
  - `04-install-pangolin-server.sh`
  - `05-capture-setup-token.sh`
  - `06-verify-pangolin-server.sh`
  - `07-rollback-pangolin-server.sh`
- Updated:
  - `00-run-all.sh` now orchestrates steps `01` through `06`
- Removed from active flow:
  - `03-install-k3s.sh`
  - `04-install-eso.sh`
  - `05-apply-secret-bridge.sh`
  - `06-pangolin-preflight.sh`
  - `07-pangolin-deploy.sh`
  - `08-pangolin-verify.sh`
  - `09-pangolin-rollback.sh`

3. Updated canonical vars:
- `ops/ansible/group_vars/vps.yml`
- Added:
  - `pangolin_install_dir`
  - `pangolin_installer_url`
- Removed active VPS dependence on ESO/Helm Pangolin vars.

4. Updated docs:
- `scripts/2-ops/vps/README.md` aligned to new runbook flow.
- `docs/dependencies.md` now tracks installer dependency and records Helm repo status.
- `docs/pangolin/0001-deploy-model.md` updated to mark installer path as active and helm path blocked upstream (for pangolin-server).
- `docs/system-map.md` updated for VPS edge runtime model.
- `ops/ansible/README.md` wrapper sequence updated.

## Current State
- ✅ SSH + Ansible connectivity is established to VPS.
- ✅ Host bootstrap scripts are idempotent enough for repeated use.
- ✅ Runtime/install/token/verify/rollback scripts exist and pass shell syntax checks.
- ⏳ Pangolin installer flow requires interactive execution during step `04`.
- ⏳ Setup token extraction + OP storage validated via step `05`.

## Next Steps
1. Run `scripts/2-ops/vps/00-run-all.sh`.
2. During `04-install-pangolin-server.sh`, execute the printed interactive SSH installer command.
3. Run `05-capture-setup-token.sh`, store setup token in 1Password.
4. Run `06-verify-pangolin-server.sh`.
5. Keep `07-rollback-pangolin-server.sh` as manual recovery path.
