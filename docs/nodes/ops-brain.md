# Node: ops-brain

## Identity
- Host alias: `ops-brain`
- Role: internal k3s control plane and monitoring node
- Hardware class: 16 GB laptop

## Access
- SSH user: `virgil`
- SSH port: `22`
- Root access: bootstrap/break-glass only
- Expected admin model: `virgil` + sudo

## Network
- Inventory source: `ops/ansible/inventory/ops-brain.ini`
- Current automation IP is stored in inventory, not duplicated here
- Public routes should not be inferred from this node doc

## Runtime
- OS: Debian 12
- Cluster role: single-node k3s control plane (current)
- Intended services: monitoring stack, operator-facing observability services, Newt
- Not intended for: CI/CD core services, general workload sprawl

## Verify
1. `scripts/2-ops/ops-brain/07-verify-cluster.sh`
2. `ops/ansible/group_vars/ops_brain.yml`
3. `docs/progress_log/0100-ops-brain-bootstrap-complete.md`
