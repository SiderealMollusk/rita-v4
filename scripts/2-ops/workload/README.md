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
9. `09-rebuild-nextcloud-vm.sh`
10. `10-rebuild-talk-hpb-vm.sh`
11. `11-bootstrap-nextcloud-host.sh`
12. `12-install-nextcloud-core.sh`
13. `13-verify-nextcloud-core.sh`
14. `15-bootstrap-nextcloud-db.sh`
15. `16-enable-nextcloud-suite.sh`
16. `17-enable-nextcloud-flow.sh`
17. `18-register-nextcloud-appapi-daemon.sh`
18. `19-deploy-nextcloud-flow-exapp.sh`
19. `20-patch-nextcloud-flow-oss.sh`
20. `21-wire-vm-newt-connectors.sh`

Notes:
1. `workload-pve` is the canonical Proxmox substrate identity.
2. `workload-vm-worker` is the canonical guest identity.
3. the in-guest hostname is expected to be `workload`.
4. this lane is intentionally separate from `platform` so the repo can keep platform-service and workload-service decisions explicit.
5. durable machine-onboarding expectations live in `docs/adding-a-machine.md`.
6. the rebuild path is not considered successful until `03-validate-vm.sh` passes.
7. Nextcloud is being prepared as the first major workload-lane collaboration suite.
8. the Nextcloud app manifests are scaffolded under `ops/gitops/workload/apps/` but are not yet rooted live until the secret/domain activation step is intentional.
9. `workload-pve` now reserves dedicated standalone VM definitions for `nextcloud-core` and `nextcloud-talk-hpb`; the old giant-worker assumption is no longer the only modeled capacity shape.
10. `09-rebuild-nextcloud-vm.sh` and `10-rebuild-talk-hpb-vm.sh` create the dedicated VMs directly from the same Proxmox template lane as the worker.
11. `11-bootstrap-nextcloud-host.sh`, `12-install-nextcloud-core.sh`, and `13-verify-nextcloud-core.sh` are the VM-first operator path for bringing up a boring, tuned Nextcloud core before any Flow/AppAPI experimentation.
12. `17-enable-nextcloud-flow.sh` is separate from the base suite bootstrap because Flow depends on AppAPI/webhook listeners plus an AppAPI deploy daemon.
13. `18-register-nextcloud-appapi-daemon.sh` registers the AppAPI daemon non-interactively once the HaRP or Docker-backed endpoint exists.
14. `19-deploy-nextcloud-flow-exapp.sh` deploys the Flow ExApp through the registered daemon rather than only enabling the UI-side app package.
15. `20-patch-nextcloud-flow-oss.sh` reapplies the current Flow `1.3.1` Windmill OSS workaround after an ExApp redeploy until upstream `nextcloud/flow` fixes the initialization bug.
16. `21-wire-vm-newt-connectors.sh` wires Pangolin Newt connector services on VM records from `ops/pangolin/sites/required-sites.yaml`.
