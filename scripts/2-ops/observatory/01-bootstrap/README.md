# Ops-Brain Bootstrap Phase

This phase prepares the laptop as an internal k3s control-plane node.

Execution order:
1. `../01-ansible-ping.sh`
2. `../02-bootstrap-host.sh`
3. `../03-configure-power-policy.sh`
4. `../04-install-k3s.sh`
5. `../05-install-helm.sh`
6. `../06-label-node.sh`
7. `../07-verify-cluster.sh`

Use `00-run-all.sh` in this directory to run the full bootstrap phase.
