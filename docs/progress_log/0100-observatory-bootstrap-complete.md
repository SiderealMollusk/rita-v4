# 0100 - Observatory Bootstrap Complete
Status: DONE
Date: 2026-02-28

## Summary
The fresh Debian 12 `observatory` laptop bootstrap path is now working from repo automation.

Validated outcomes:
1. SSH access as `virgil` works with the OP-managed admin key.
2. Ansible connectivity against `ops/ansible/inventory/observatory.ini` works.
3. Base host bootstrap completed.
4. No-sleep / lid-close-ignore policy completed.
5. Single-node k3s control plane installed successfully.
6. Helm installed successfully.
7. The node was labeled `rita.role=observatory`.

## What Was Added
New canonical observatory automation:
1. `ops/ansible/group_vars/observatory.yml`
2. `ops/ansible/playbooks/11-bootstrap-observatory.yml`
3. `ops/ansible/playbooks/12-configure-observatory-power.yml`
4. `ops/ansible/playbooks/21-install-k3s-observatory.yml`
5. `ops/ansible/playbooks/22-install-helm-observatory.yml`
6. `ops/ansible/playbooks/23-label-observatory-node.yml`
7. `scripts/2-ops/observatory/00-run-all.sh`
8. `scripts/2-ops/observatory/01-ansible-ping.sh`
9. `scripts/2-ops/observatory/02-bootstrap-host.sh`
10. `scripts/2-ops/observatory/03-configure-power-policy.sh`
11. `scripts/2-ops/observatory/04-install-k3s.sh`
12. `scripts/2-ops/observatory/05-install-helm.sh`
13. `scripts/2-ops/observatory/06-label-node.sh`

## Bug Found and Fixed
The first run of the power-policy playbook failed because Debian 12 did not already have `/etc/systemd/logind.conf.d`.

Fix:
1. `12-configure-observatory-power.yml` now creates `/etc/systemd/logind.conf.d` before writing the drop-in.

## Operational Notes
1. `01-ansible-ping.sh` is now correctly treated as an SSH/connectivity check, not a privilege check.
2. `virgil` on `observatory` needed sudo configured before the runbook could be used end-to-end.
3. Docker is intentionally not part of the laptop bootstrap path because k3s uses containerd.
4. The laptop remains schedulable for now; taints are deferred until more physical nodes join.

## Current State
The `observatory` laptop is now ready for:
1. cluster verification runbooks
2. monitoring namespace/bootstrap work
3. Helm chart installation for the monitoring stack

## Next Steps
1. add `07-verify-cluster.sh` for `observatory`
2. create monitoring stack install scripts and playbooks
3. define storage expectations for Prometheus, Grafana, and Loki on the laptop
4. decide which monitoring surfaces will later be exposed through Pangolin
