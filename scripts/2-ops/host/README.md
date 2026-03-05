# Host Ops Runbooks

This directory is for operator-boundary tasks that must run on the Mac host, not inside the devcontainer.

Freshness anchor:
1. [0260-host-blueprint-apply-script-added.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0260-host-blueprint-apply-script-added.md)

Rules:
1. no-arg and opinionated
2. host-only guarded
3. uses the least-strict viable 1Password auth mode for the task:
   - read-only tasks may use service-account or human session
   - write/mutation tasks may still require a real human operator session
4. bridges repo automation to external/operator actions where the privilege lives on the host

Current host-only responsibilities:
1. bootstrap identity
2. write/update secrets in 1Password
3. run Pangolin CLI mutations using the host-side authenticated operator session
4. run Uptime Kuma API mutations using host-held operator credentials

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
  - `newt_id`
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

7. `21-apply-nextcloud-blueprint.sh`
- applies the canonical Pangolin public resource for `app.virgil.info`
- targets `nextcloud-edge.workload.svc.cluster.local:8080`
- runs on the Mac host with Pangolin CLI
- assumes Pangolin CLI is already authenticated
- reads the Pangolin site identifier from `pangolin_site_ops_brain`

8. `23-apply-nextcloud-cloud-blueprint.sh`
- applies a temporary validation route for `cloud.virgil.info`
- targets the dedicated `nextcloud-core` VM at `192.168.6.183:80`
- leaves the older `app.virgil.info` route untouched during validation

9. `24-register-pangolin-site-credentials.sh`
- single-site credential registration for the canonical `ops_brain` site
- writes or updates the canonical 1Password secure note from `ops_brain.yml`
- requires operator 1Password human-session auth (not service-account mode)
- validates pasted Helm snippet endpoint/newt_id/secret against repo endpoint

10. `25-register-pangolin-sites.sh`
- batch wrapper for registering multiple Pangolin site credential notes
- reads canonical slugs from `ops/pangolin/sites/ops-brain-site-slugs.txt`
- derives canonical names/items from slug + `pangolin_newt_credentials_item_prefix`
- keeps one `Secure Note` item per site

11. `26-pangolin-api-readonly-check.sh`
- read-only Pangolin + OP contract check
- reads required sites from `ops/pangolin/sites/required-sites.yaml`
- verifies each required site exists in Pangolin
- verifies each required OP item exists and carries canonical fields

12. `27-reconcile-pangolin-sites.sh`
- operator mutation script for Pangolin site lifecycle
- creates missing required sites through Pangolin API
- writes/updates canonical per-site Secure Notes in OP
- requires operator human-session OP auth

13. `28-verify-pangolin-sites-and-newt.sh`
- end-to-end verify gate
- runs script `26` first
- verifies VM Newt systemd service state for VM connector records
- checks Pangolin `online` state for required sites

14. `29-teardown-pangolin-sites.sh`
- cleanly deletes all `managed` Pangolin sites from canonical `required-sites.yaml`
- optionally deletes matching OP secure-note items (enabled by default)
- refuses to run without explicit confirm guard:
  - `PANGOLIN_TEARDOWN_CONFIRM=delete-managed-sites`
- optional OP item behavior:
  - `PANGOLIN_TEARDOWN_DELETE_OP_ITEMS=1` (default)
  - `PANGOLIN_TEARDOWN_DELETE_OP_ITEMS=0` (keep OP items)

15. `30-seed-kuma-monitors.sh`
- seeds Uptime Kuma monitors from the canonical Pangolin monitoring blueprint
- runs on the Mac host
- uses a temporary SSH-backed tunnel to reach Kuma directly on `ops-brain`
- reads Kuma admin credentials from `kuma_ops_brain_admin` in 1Password
- creates the 1Password login item if it is missing and you provide credentials interactively

16. `31-apply-n8n-blueprint.sh`
- applies the canonical Pangolin public resource for `n8n.virgil.info`
- targets `10.43.171.251:5678` via the `n8n-vm` site identifier
- reads OP item/title from `ops/pangolin/sites/required-sites.yaml` slug `n8n_vm`
- expects Pangolin CLI host session auth to already be active

Notes:
1. site creation/reconciliation is now handled by `27-reconcile-pangolin-sites.sh` from canonical required-site records.
2. service-account mode is acceptable for read-only host tasks that only need to resolve secrets or identifiers; human-session mode is required for any 1Password write/update flow.
3. blueprint YAML is non-secret; the sensitive boundary is the Pangolin CLI auth/session used to apply it.
4. the Pangolin CLI install belongs here because the operator-authenticated mutation workflow belongs here.
