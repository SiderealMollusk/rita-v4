# Platform Worker Runbooks

These scripts manage the platform worker lane after VM `9200` exists and is reachable by SSH.

Freshness anchor:
1. [0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md)
2. [0400-platform-worker-joined-and-cluster-mismatch-found.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0400-platform-worker-joined-and-cluster-mismatch-found.md)
3. [0170-platform-worker-execution-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0170-platform-worker-execution-plan.md)

Top-level orchestration:
1. `00-run-all.sh`
- runs the current worker bootstrap sequence in order

Direct-entry scripts:
1. `01-ansible-ping.sh`
2. `02-bootstrap-host.sh`
3. `03-install-k3s-agent.sh`
4. `04-label-nodes.sh`
5. `05-verify-cluster.sh`
6. `06-bootstrap-flux-github.sh`
7. `07-report-backup-state.sh`

Notes:
1. `ops/ansible/inventory/platform.ini` and `ops/ansible/inventory/internal-cluster.ini` carry the current `platform-vm-worker` management IP.
2. `ops-brain` remains the control plane and monitoring home.
3. This path assumes the worker VM inventory alias is `platform-vm-worker` and the in-guest hostname remains `platform`.
4. Flux bootstrap is intentionally host-driven so GitHub auth stays in the operator environment.
5. Durable machine-onboarding expectations live in `docs/adding-a-machine.md`.
