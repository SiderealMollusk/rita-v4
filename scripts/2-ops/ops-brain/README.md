# Ops-Brain Runbooks

These scripts manage the laptop that acts as the `ops-brain`.

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

Services lane:
1. `10-install-newt.sh`

Notes:
1. This path assumes fresh Debian 12 with working `virgil` SSH + sudo.
2. Docker is not part of this path; k3s uses containerd.
3. The laptop remains schedulable for now; taints come later when more physical nodes join.
4. `00-run-all.sh` is intentionally stricter now: it runs bootstrap and services, and stops on the first unmet prerequisite.
