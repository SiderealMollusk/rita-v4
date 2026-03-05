# Nextcloud Instance Registry

This directory tracks all known Nextcloud instances and the single official instance pointer.

Canonical file:
1. [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml)

Contract:
1. `official_instance` names the current source of truth for production/operator flows.
2. `instances` maps each known instance key to technical routing/install metadata.
3. The installer wrapper [12-install-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/12-install-nextcloud-core.sh) reads this file and defaults its inventory/domain from the official instance.

Current intent:
1. `nextcloud_core_vm` is official and active.
2. `nextcloud_k3s_legacy` is retained as legacy context during migration windows.
