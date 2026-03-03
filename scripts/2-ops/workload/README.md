# Workload Runbooks

These scripts manage the server-side workload lane.

Freshness anchor:
1. [0430-workload-node-joined-and-api-policy-extended.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0430-workload-node-joined-and-api-policy-extended.md)
2. [0460-nextcloud-gitops-scaffolded.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0460-nextcloud-gitops-scaffolded.md)
3. [0190-workload-node-onboarding-and-tainting.md](/Users/virgil/Dev/rita-v4/docs/plans/0190-workload-node-onboarding-and-tainting.md)

Top-level orchestration:
1. `00-run-all.sh`
- runs the current workload bootstrap and join sequence in order

Direct-entry scripts:
1. `01-inspect-proxmox.sh`
2. `02-rebuild-workload-vm.sh`
3. `03-validate-vm.sh`
4. `04-ansible-ping.sh`
5. `05-bootstrap-host.sh`
6. `06-install-k3s-agent.sh`
7. `07-label-node.sh`
8. `08-verify-node.sh`
9. `15-bootstrap-nextcloud-db.sh`
10. `16-enable-nextcloud-suite.sh`

Notes:
1. `workload-pve` is the canonical Proxmox substrate identity.
2. `workload-vm-worker` is the canonical guest identity.
3. the in-guest hostname is expected to be `workload`.
4. this lane is intentionally separate from `platform` so the repo can keep platform-service and workload-service decisions explicit.
5. durable machine-onboarding expectations live in `docs/adding-a-machine.md`.
6. the rebuild path is not considered successful until `03-validate-vm.sh` passes.
7. Nextcloud is being prepared as the first major workload-lane collaboration suite.
8. the Nextcloud app manifests are scaffolded under `ops/gitops/workload/apps/` but are not yet rooted live until the secret/domain activation step is intentional.
