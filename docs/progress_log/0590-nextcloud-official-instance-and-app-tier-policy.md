# 0590 - Nextcloud Official Instance And App Tier Policy

Date: 2026-03-05

## Summary

Nextcloud now has an explicit repo-level instance registry and official-instance pointer so operator flows can target one canonical deployment even when multiple instances exist.

App management was also split into stable/easy vs experimental tiers and is now enforced during install.

## What Changed

1. Added a canonical Nextcloud instance registry:
- [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml)
- [README.md](/Users/virgil/Dev/rita-v4/ops/nextcloud/README.md)

2. Added official-instance resolution to the VM install wrapper:
- [12-install-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/12-install-nextcloud-core.sh)

This script now:
1. reads `official_instance` from `ops/nextcloud/instances.yaml`
2. derives inventory/domain defaults from that record
3. fails fast if the official record is not VM-backed for this runbook

3. Added app tier SoT to Nextcloud group vars:
- [nextcloud.yml](/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/nextcloud.yml)

New policy variables:
1. `nextcloud_apps_easy` (default baseline apps)
2. `nextcloud_apps_experimental` (higher-risk/noisier integrations)
3. `nextcloud_enable_experimental_apps` (gate)
4. `nextcloud_required_apps` (computed desired set)
5. `nextcloud_disabled_apps` (explicit removals)

4. Enforced app desired state in install playbook:
- [33-install-nextcloud-core.yml](/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/33-install-nextcloud-core.yml)

Added:
1. `occ app:enable` loop for `nextcloud_required_apps`
2. `occ app:disable` loop for `nextcloud_disabled_apps`

## User/Auth Runbook Outcome

Password rotation runbooks were added and hardened:
1. [22-rotate-nextcloud-user-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/22-rotate-nextcloud-user-password.sh) (logic + args)
2. [23-rotate-nextcloud-virgil-admin-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/23-rotate-nextcloud-virgil-admin-password.sh) (no-arg wrapper)

Behavior now supports:
1. pulling password from secondary vault `sf7a6ejbujriiv6eyicexsp4yi`
2. forcing user `virgil-admin`
3. creating user if missing
4. ensuring admin-group membership

## Why This Matters

1. The repo now distinguishes:
- "all known Nextcloud instances" vs
- "the official Nextcloud target"

2. App posture is now explicit and enforceable:
- easy/stable apps can be baseline
- experimental/integration-heavy apps can remain opt-in and reversible

3. Rebuild/migration decisions become pointer changes in SoT rather than ad-hoc operator memory.

## Validation

1. `bash -n` passed for updated workload scripts
2. `jq empty` passed for `ops/nextcloud/instances.yaml`
3. `ansible-playbook --syntax-check` passed for playbook `33-install-nextcloud-core.yml`
