# Workload Runbooks

These scripts manage the server-side workload lane.

Freshness anchor:
1. [0430-workload-node-joined-and-api-policy-extended.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0430-workload-node-joined-and-api-policy-extended.md)
2. [0460-nextcloud-gitops-scaffolded.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0460-nextcloud-gitops-scaffolded.md)
3. [0190-workload-node-onboarding-and-tainting.md](/Users/virgil/Dev/rita-v4/docs/plans/0190-workload-node-onboarding-and-tainting.md)

Top-level orchestration:
1. `00-run-all.sh`
- runs the current workload bootstrap and join sequence in order

Snapshot discipline (recommended before risky moves):
1. Create snapshots on `workload-pve` (`192.168.6.11`) before these scripts:
- `09-rebuild-nextcloud-vm.sh`
- `10-rebuild-talk-hpb-vm.sh`
- `12-install-nextcloud-core.sh`
- `18-register-nextcloud-appapi-daemon.sh`
- `19-deploy-nextcloud-flow-exapp.sh`
- `20-patch-nextcloud-flow-oss.sh`
2. Snapshot commands (copy/paste):
```bash
SNAP_TAG="pre-$(date +%Y%m%d-%H%M)-nextcloud-change"
ssh root@192.168.6.11 "qm snapshot 9301 ${SNAP_TAG} --description 'pre nextcloud risky move' --vmstate 0"
ssh root@192.168.6.11 "qm snapshot 9302 ${SNAP_TAG} --description 'pre talk-hpb risky move' --vmstate 0"
```
3. Optional rollback:
```bash
ssh root@192.168.6.11 "qm rollback 9301 ${SNAP_TAG}"
ssh root@192.168.6.11 "qm rollback 9302 ${SNAP_TAG}"
```
4. Optional post-change cleanup (after verification passes):
```bash
ssh root@192.168.6.11 "qm delsnapshot 9301 ${SNAP_TAG} --force 1"
ssh root@192.168.6.11 "qm delsnapshot 9302 ${SNAP_TAG} --force 1"
```

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
21. `22-rotate-nextcloud-user-password.sh`
22. `23-rotate-nextcloud-virgil-admin-password.sh`
23. `24-rotate-nextcloud-virgil-password.sh`
24. `25-configure-nextcloud-talk-runtime.sh`
25. `26-configure-nextcloud-talk-runtime.sh`
26. `27-verify-nextcloud-talk-runtime.sh`
27. `28-seed-nextcloud-talk-signaling-secret-op.sh`
28. `29-rebuild-n8n-vm.sh`
29. `30-bootstrap-n8n-host.sh`
30. `31-install-n8n-k3s-agent.sh`
31. `32-label-n8n-node.sh`
32. `33-verify-n8n-node.sh`
33. `34-verify-nextcloud-exapps-health.sh`
34. `35-snapshot-nextcloud-pair.sh`
35. `36-rollback-nextcloud-pair.sh`
36. `37-prune-nextcloud-snapshots.sh`
37. `38-configure-nextcloud-main-users.sh`
38. `40-floating-checkpoint.sh`
39. `39-bring-up-n8n-vm-k8s-pangolin.sh`
40. `41-install-nextcloud-talk-hpb-runtime.sh`
41. `42-verify-nextcloud-talk-hpb-runtime.sh`
42. `43-bring-up-nextcloud-talk-hpb.sh`
43. `44-clear-nextcloud-throttle-and-show-source.sh`
44. `45-flush-nextcloud-logs.sh`
45. `46-configure-nextcloud-appapi-harp-runtime.sh`

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
12. `17-enable-nextcloud-flow.sh` is VM-native and enables Flow prerequisites (`app_api`, `webhook_listeners`) on the official Nextcloud VM before ExApp deployment.
13. `18-register-nextcloud-appapi-daemon.sh` is VM-native and registers the AppAPI daemon directly through `occ` on the official Nextcloud VM (no kubectl/k8s dependency); default mode is `harp` and supports `docker-local`/`manual-install` as explicit fallbacks.
14. `19-deploy-nextcloud-flow-exapp.sh` is VM-native and registers Flow ExApp against the configured AppAPI daemon.
15. `20-patch-nextcloud-flow-oss.sh` reapplies the current Flow `1.3.1` Windmill OSS workaround after an ExApp redeploy until upstream `nextcloud/flow` fixes the initialization bug.
16. `21-wire-vm-newt-connectors.sh` wires Pangolin Newt connector services on VM records from `ops/pangolin/sites/required-sites.yaml`.
17. `22-rotate-nextcloud-user-password.sh` is the argument-driven password rotation path that reads username/password from a 1Password item and applies it to a Nextcloud user with `occ user:resetpassword`.
18. `23-rotate-nextcloud-virgil-admin-password.sh` is the no-arg wrapper for the canonical `nextcloud-main-users` vault item `virgil-admin`.
19. Nextcloud official-instance defaults now come from `ops/nextcloud/instances.yaml` so operator flows can keep one technical pointer while still tracking legacy instances.
20. Nextcloud app policy is split into `easy/core` and `experimental` tiers in `ops/ansible/group_vars/nextcloud.yml`; install playbook `33` enforces this desired app state.
21. `24-rotate-nextcloud-virgil-password.sh` is the no-arg wrapper for item `virgil` and enforces OP username match before applying password.
22. Talk runtime desired state is tracked in `ops/nextcloud/talk-runtime.yaml`; use `26-configure-nextcloud-talk-runtime.sh` to apply and `27-verify-nextcloud-talk-runtime.sh` to verify.
23. Talk signaling secret is sourced from 1Password via `op://5vr4hef2746tpplvjx424xafvu/nextcloud-talk-runtime/password` (item: `nextcloud-talk-runtime`, field: `password`).
24. `28-seed-nextcloud-talk-signaling-secret-op.sh` backfills/updates that OP item from live `occ talk:signaling:list` output so runtime config can stay secret-free in git.
25. `29-rebuild-n8n-vm.sh` provisions a dedicated `n8n-vm` from `workload-pve` template capacity.
26. `30-bootstrap-n8n-host.sh` through `33-verify-n8n-node.sh` join and verify `n8n-vm` as a dedicated workload-labeled k3s node with hostname `n8n`.
27. `34-verify-nextcloud-exapps-health.sh` is a VM-first regression gate for AppAPI/ExApps that fails on stale signature loops (`Invalid signature for ExApp`), unauthorized ExApp state polling (`401` on `/ocs/v1.php/apps/app_api/ex-app/state`), and unexpected caller IPs (for example stale sidecars on non-official hosts).
28. Post-change verification is now automatic:
- `18-register-nextcloud-appapi-daemon.sh` runs `34` in daemon-only mode (`EXAPP_REQUIRE_APP_ENABLED=0`) by default.
- `19-deploy-nextcloud-flow-exapp.sh` runs `34` by default.
- `20-patch-nextcloud-flow-oss.sh` runs `34` by default.
- Set `APPAPI_POST_VERIFY=0` or `FLOW_POST_VERIFY=0` only for deliberate break-glass debugging.
29. Pre-change snapshots are automatic in `critical` mode for high-risk Nextcloud scripts:
- `12-install-nextcloud-core.sh`
- `16-enable-nextcloud-suite.sh`
- `18-register-nextcloud-appapi-daemon.sh`
- `19-deploy-nextcloud-flow-exapp.sh`
- `20-patch-nextcloud-flow-oss.sh`
- `26-configure-nextcloud-talk-runtime.sh`
- Toggle with `NEXTCLOUD_SNAPSHOT_MODE=critical|off` (default: `critical`).
- Legacy flag `NEXTCLOUD_AUTO_SNAPSHOT_PRE=0|1` is still honored for compatibility.
30. Snapshot utility scripts:
- `35-snapshot-nextcloud-pair.sh` creates coordinated snapshots for VM IDs `9301` and `9302`.
- `36-rollback-nextcloud-pair.sh` rolls both VMs back to the same tag (`NEXTCLOUD_ROLLBACK_CONFIRM=rollback-nextcloud-pair` required).
- `37-prune-nextcloud-snapshots.sh` applies retention pruning (`NEXTCLOUD_PRUNE_CONFIRM=prune-nextcloud-snapshots` required).
31. Nextcloud main user SoT is now tracked in `ops/nextcloud/main-users.yaml` (vault ID, item mapping, and role intent), and applied via `38-configure-nextcloud-main-users.sh`.
32. `40-floating-checkpoint.sh` is the intentional "save-point" helper: it takes a coordinated Nextcloud VM pair snapshot and auto-generates a new progress note baseline entry under `docs/progress_log/`.
33. The floating checkpoint script is expected to be manually renumbered over time as validation confidence increases (for example `40-*` -> `50-*`), so the lane reflects the current baseline ritual.
34. `39-bring-up-n8n-vm-k8s-pangolin.sh` is the canonical full chain for n8n: VM rebuild, k3s join/label/verify, ESO+n8n runtime reconcile, Pangolin site reconcile, VM Newt connector wiring, n8n resource apply, and end-state verification.
35. `41-install-nextcloud-talk-hpb-runtime.sh` codifies HPB runtime provisioning on `talk-hpb-vm` (signaling, janus, nats, and systemd service wiring) with snapshot guardrails.
36. `42-verify-nextcloud-talk-hpb-runtime.sh` validates HPB service/process/port state plus public signaling endpoint reachability and Nextcloud Talk runtime registration.
37. `43-bring-up-nextcloud-talk-hpb.sh` is the no-adhoc orchestration entrypoint: install HPB runtime, apply Talk runtime SoT, and run HPB verification.
38. Optional cross-lane validation from `43`:
- set `HPB_VERIFY_SITES=1` to append Pangolin/Newt global site verification.
- default keeps HPB success scoped to HPB/Talk criteria so unrelated missing sites do not block the run.
39. `44-clear-nextcloud-throttle-and-show-source.sh` resets Nextcloud brute-force counters for a target IP and prints recent likely source lines (failed auth + AppAPI polling) so operators can separate stale client credentials from proxy/header issues quickly.
40. `45-flush-nextcloud-logs.sh` truncates Nextcloud and Nginx logs on the official Nextcloud VM (`nextcloud.log`, `access.log`, `error.log`) behind an explicit confirm token (`NEXTCLOUD_LOG_FLUSH_CONFIRM=flush-nextcloud-logs`).
41. AppAPI daemon/HaRP SoT now lives in `ops/nextcloud/appapi-runtime.yaml`; use `46-configure-nextcloud-appapi-harp-runtime.sh` to apply VM-local HaRP runtime + default daemon registration deterministically.
