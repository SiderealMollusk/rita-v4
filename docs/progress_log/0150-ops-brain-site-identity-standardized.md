# 0150 Ops-Brain Site Identity Standardized

As of this update, the Pangolin site identity for the laptop path was standardized away from `monitoring` and onto `ops-brain`.

## Canonical contract

1. Pangolin site display name:
   - `ops-brain`
2. 1Password item title:
   - `pangolin_site_ops_brain`
3. 1Password field `name`:
   - `ops-brain`

## Why this changed

The earlier `monitoring` naming was too narrow.

The laptop is not only a monitoring destination:

1. it is the internal control-plane node
2. it is the intended Newt-connected site identity
3. it may expose multiple operator-facing services over time

Using `ops-brain` keeps the site identity aligned with the machine role instead of one workload on it.

## Script changes

Renamed:

1. `scripts/2-ops/host/10-write-ops-brain-pangolin-site-secret.sh`
2. `scripts/2-ops/devcontainer/20-validate-ops-brain-pangolin-site.sh`

Updated:

1. `ops/ansible/group_vars/ops_brain.yml`
2. Pangolin human-registration doc
3. references in plans and progress notes

## Safe reading guidance

If older notes mention `pangolin_site_monitoring` or a `monitoring` Pangolin site, treat them as superseded by this update.
