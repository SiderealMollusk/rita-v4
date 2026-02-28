# Ops-Brain Runbooks

These scripts bootstrap the laptop that acts as the `ops-brain`.

Execution order:
1. `01-ansible-ping.sh`
2. `02-bootstrap-host.sh`
3. `03-configure-power-policy.sh`
4. `04-install-k3s.sh`
5. `05-install-helm.sh`
6. `06-label-node.sh`
7. `07-verify-cluster.sh`

Use `00-run-all.sh` to run the whole sequence.

Notes:
1. This path assumes fresh Debian 12 with working `virgil` SSH + sudo.
2. Docker is not part of this path; k3s uses containerd.
3. The laptop remains schedulable for now; taints come later when more physical nodes join.
