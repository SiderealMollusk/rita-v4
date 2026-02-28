# Host Ops Runbooks

This directory is for operator-boundary tasks that must run on the Mac host, not inside the devcontainer.

Rules:
1. no-arg and opinionated
2. host-only guarded
3. assumes real 1Password user session, not service-account mode
4. bridges repo automation to external/operator actions like SSH bootstrap and secret writing

Current scripts:
1. `00-run-all.sh`
- runs the currently safe host-side sequence

2. `01-seed-ops-brain-ssh.sh`
- seeds SSH/admin access for `ops-brain` from canonical inventory
- expects root password SSH on the fresh machine

3. `02-seed-main-vps-ssh.sh`
- seeds SSH/admin access for `main-vps` from canonical inventory
- expects root password SSH on the fresh machine

4. `10-write-ops-brain-newt-secret.sh`
- creates or updates the `ops-brain` Newt credential item in 1Password
- stores:
  - `endpoint`
  - `id`
  - `secret`

Notes:
1. site creation with Pangolin CLI is a separate host-side step and should feed into `10-write-ops-brain-newt-secret.sh`.
2. service-account mode is intentionally blocked here because these scripts are operator workflows.
