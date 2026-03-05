# Observatory Runbooks

These scripts manage the laptop that acts as the `observatory`.

Freshness anchor:
1. [0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md)
2. [0410-flux-bootstrap-blocked-by-kubeconfig-and-host-api-tech-debt.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0410-flux-bootstrap-blocked-by-kubeconfig-and-host-api-tech-debt.md)
3. [0400-platform-worker-joined-and-cluster-mismatch-found.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0400-platform-worker-joined-and-cluster-mismatch-found.md)

Top-level orchestration:
1. `00-run-all.sh`
- runs all currently known phases in order

Phase directories:
1. `01-bootstrap/`
- machine + cluster bring-up
2. `02-services/`
- service/workload installation after bootstrap

Direct-entry scripts remain at the top level for targeted reruns.

Bootstrap lane:
1. `01-ansible-ping.sh`
2. `02-bootstrap-host.sh`
3. `03-configure-power-policy.sh`
4. `04-install-k3s.sh`
5. `05-install-helm.sh`
6. `06-label-node.sh`
7. `07-verify-cluster.sh`
8. `08-sync-kubeconfig.sh`

Services lane:
1. `10-install-newt.sh`
2. `11-install-monitoring-stack.sh`
3. `12-verify-monitoring-stack.sh`
4. `13-install-eso.sh`
5. `14-apply-secret-bridge.sh`

Notes:
1. This path assumes fresh Debian 12 with working `virgil` SSH + sudo.
2. Docker is not part of this path; k3s uses containerd.
3. The laptop remains schedulable for now; taints come later when more physical nodes join.
4. `00-run-all.sh` is intentionally stricter now: it runs bootstrap and services, and stops on the first unmet prerequisite.
5. The first-pass monitoring stack is:
   - `kube-prometheus-stack`
   - `loki`
   - `promtail`
   - `uptime-kuma`
6. Monitoring stays internal first; Pangolin exposure comes after internal verification.
7. Uptime Kuma is deployed as part of the monitoring stack, but monitor definitions are a separate seeded layer.
8. `08-sync-kubeconfig.sh` is the canonical rerender path for `/home/virgil/.kube/config` on observatory when host-side consumers need a durable kubeconfig.
9. Durable machine-onboarding expectations live in `docs/adding-a-machine.md`.
10. External Secrets on the internal cluster is a cluster capability bootstrap, not a platform app.
11. `14-apply-secret-bridge.sh` intentionally applies the canonical `onepassword-cluster-store.yaml` from `ops/gitops/` after creating the `op-token` secret.

Current capacity order:
1. bootstrap host
2. bootstrap cluster
3. connect site with Newt
4. install monitoring stack
5. verify cluster-local service reachability from Newt
6. expose selected services later through Pangolin resource declarations
