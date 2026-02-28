# 0100 - Ops-Brain Bootstrap Complete
Status: DONE
Date: 2026-02-28

## Summary
The fresh Debian 12 `ops-brain` laptop bootstrap path is now working from repo automation.

Validated outcomes:
1. SSH access as `virgil` works with the OP-managed admin key.
2. Ansible connectivity against `ops/ansible/inventory/ops-brain.ini` works.
3. Base host bootstrap completed.
4. No-sleep / lid-close-ignore policy completed.
5. Single-node k3s control plane installed successfully.
6. Helm installed successfully.
7. The node was labeled `rita.role=ops-brain`.

## What Was Added
New canonical ops-brain automation:
1. `ops/ansible/group_vars/ops_brain.yml`
2. `ops/ansible/playbooks/11-bootstrap-ops-brain.yml`
3. `ops/ansible/playbooks/12-configure-ops-brain-power.yml`
4. `ops/ansible/playbooks/21-install-k3s-ops-brain.yml`
5. `ops/ansible/playbooks/22-install-helm-ops-brain.yml`
6. `ops/ansible/playbooks/23-label-ops-brain-node.yml`
7. `scripts/2-ops/ops-brain/00-run-all.sh`
8. `scripts/2-ops/ops-brain/01-ansible-ping.sh`
9. `scripts/2-ops/ops-brain/02-bootstrap-host.sh`
10. `scripts/2-ops/ops-brain/03-configure-power-policy.sh`
11. `scripts/2-ops/ops-brain/04-install-k3s.sh`
12. `scripts/2-ops/ops-brain/05-install-helm.sh`
13. `scripts/2-ops/ops-brain/06-label-node.sh`

## Bug Found and Fixed
The first run of the power-policy playbook failed because Debian 12 did not already have `/etc/systemd/logind.conf.d`.

Fix:
1. `12-configure-ops-brain-power.yml` now creates `/etc/systemd/logind.conf.d` before writing the drop-in.

## Operational Notes
1. `01-ansible-ping.sh` is now correctly treated as an SSH/connectivity check, not a privilege check.
2. `virgil` on `ops-brain` needed sudo configured before the runbook could be used end-to-end.
3. Docker is intentionally not part of the laptop bootstrap path because k3s uses containerd.
4. The laptop remains schedulable for now; taints are deferred until more physical nodes join.

## Current State
The `ops-brain` laptop is now ready for:
1. cluster verification runbooks
2. monitoring namespace/bootstrap work
3. Helm chart installation for the monitoring stack

## Next Steps
1. add `07-verify-cluster.sh` for `ops-brain`
2. create monitoring stack install scripts and playbooks
3. define storage expectations for Prometheus, Grafana, and Loki on the laptop
4. decide which monitoring surfaces will later be exposed through Pangolin
