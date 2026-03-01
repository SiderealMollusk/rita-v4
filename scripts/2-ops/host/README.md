# Host Ops Runbooks

This directory is for operator-boundary tasks that must run on the Mac host, not inside the devcontainer.

Freshness anchor:
1. [0260-host-blueprint-apply-script-added.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0260-host-blueprint-apply-script-added.md)

Rules:
1. no-arg and opinionated
2. host-only guarded
3. assumes real 1Password user session, not service-account mode
4. bridges repo automation to external/operator actions where the privilege lives on the host

Current host-only responsibilities:
1. bootstrap identity
2. write/update secrets in 1Password
3. run Pangolin CLI mutations using the host-side authenticated operator session

This directory is intentionally small. If a task does not need host-held privilege, it should live elsewhere.

Current scripts:
1. `00-run-all.sh`
- runs the currently safe host-side sequence

2. `01-seed-ops-brain-ssh.sh`
- seeds SSH/admin access for `ops-brain` from canonical inventory
- expects root password SSH on the fresh machine

3. `02-seed-main-vps-ssh.sh`
- seeds SSH/admin access for `main-vps` from canonical inventory
- expects root password SSH on the fresh machine

4. `10-write-ops-brain-pangolin-site-secret.sh`
- creates or updates the `ops-brain` Newt credential item in 1Password
- requires that the Pangolin site already exists
- prompts for the Pangolin site name
- ingests the rendered Pangolin Helm snippet by paste
- extracts and stores:
  - `endpoint`
  - `identifier`
  - `id`
  - `secret`

5. `11-install-pangolin-cli.sh`
- installs the Pangolin CLI on the Mac host if missing
- verifies the CLI is callable
- tolerates the common case where the binary exists in `~/.local/bin` before the shell `PATH` is updated

6. `20-apply-ops-brain-monitoring-blueprint.sh`
- applies the canonical draft Pangolin monitoring blueprint for `ops-brain`
- runs on the Mac host with Pangolin CLI
- assumes Pangolin CLI is already authenticated
- reads the Pangolin site identifier from `pangolin_site_ops_brain`
- resolves Pangolin CLI from `PATH` or `~/.local/bin/pangolin`

Notes:
1. site creation in Pangolin is a separate host-side/operator step and should feed into `10-write-ops-brain-pangolin-site-secret.sh`.
2. service-account mode is intentionally blocked here because these scripts are operator workflows.
3. blueprint YAML is non-secret; the sensitive boundary is the Pangolin CLI auth/session used to apply it.
4. the Pangolin CLI install belongs here because the operator-authenticated mutation workflow belongs here.
