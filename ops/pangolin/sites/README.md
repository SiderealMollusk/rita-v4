# Pangolin Site Records

This directory is the canonical home for required Pangolin site records.

Primary source:
1. `required-sites.yaml`

Contract:
1. One record per required site.
2. `display_name` is the Pangolin site name.
3. `op_item_title` is the canonical 1Password `Secure Note` item for site credentials.
4. VM connector wiring scripts consume only `connector_mode: vm` records with `newt_enabled: true`.
5. `managed_mode` controls reconcile behavior:
   - `managed`: script `27` creates/updates site + OP record
   - `legacy`: script `27` skips mutation (verify-only posture)

Operational scripts:
1. `scripts/2-ops/host/26-pangolin-api-readonly-check.sh`
2. `scripts/2-ops/host/27-reconcile-pangolin-sites.sh`
3. `scripts/2-ops/workload/21-wire-vm-newt-connectors.sh`
4. `scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh`
