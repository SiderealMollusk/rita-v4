# Newt Helm Config

This directory is the canonical home for Kubernetes-based Newt deployment config.

Current target:
1. `ops-brain` k3s cluster

Current policy:
1. install `fossorial/newt` via Helm
2. store `NEWT_ID` and `NEWT_SECRET` in 1Password only
3. source `PANGOLIN_ENDPOINT` from `ops/network/routes.yml`
4. use a Kubernetes Secret named `newt-cred`

Verification references:
1. `docs/plans/0140-ops-brain-monitoring-and-pangolin-access.md`
2. `scripts/2-ops/ops-brain/10-install-newt.sh`

## 1Password Item Contract
The install script expects an item in the configured vault with:
1. field label `id`
2. field label `secret`

The Pangolin endpoint is not read from 1Password.
It is sourced from `ops/network/routes.yml` (`pangolin_endpoint`).
