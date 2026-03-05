# 0120 - Host Lane and Observatory Orchestration
Status: DONE
Date: 2026-02-28

## Summary
The repo execution model was tightened around actual operator boundaries.

Main changes:
1. host-only/operator tasks now live in `scripts/2-ops/host/`
2. the ambiguous `scripts/2-ops/local/` lane was renamed to `scripts/2-ops/devcontainer/`
3. `observatory` runbooks were refactored into bootstrap and services phases
4. Newt-on-Kubernetes scaffolding was added for `observatory`
5. SSH ping checks now point directly at the canonical host-side reseed scripts on failure

## Why This Changed
The previous layout blurred three different contexts:
1. Mac host operator actions
2. disposable devcontainer/local k3d actions
3. real infrastructure runbooks

That ambiguity was beginning to create the wrong mental model for both humans and fresh-context agents.

## What Was Added
### Host lane
Added `scripts/2-ops/host/` for Mac-host-only actions:
1. `00-run-all.sh`
2. `01-seed-observatory-ssh.sh`
3. `02-seed-main-vps-ssh.sh`
4. `10-write-observatory-pangolin-site-secret.sh`
5. `README.md`

Purpose:
1. SSH key/bootstrap flows that require password login and real host SSH context
2. 1Password user-session workflows that should not run in service-account mode
3. operator-boundary secret writing

### Observatory orchestration layers
Added phase directories:
1. `scripts/2-ops/observatory/01-bootstrap/`
2. `scripts/2-ops/observatory/02-services/`

Current behavior:
1. top-level `scripts/2-ops/observatory/00-run-all.sh` now really runs all known phases
2. bootstrap phase runs `01-07`
3. services phase currently runs `10-install-newt.sh`

### Newt scaffolding
Added:
1. `scripts/2-ops/observatory/10-install-newt.sh`
2. `ops/helm/newt/values.observatory.yaml`
3. `ops/helm/newt/README.md`
4. Newt vars in `ops/ansible/group_vars/observatory.yml`

The intended flow is now explicit:
1. create Pangolin site from the Mac
2. store returned `id` and `secret` in 1Password
3. run `10-install-newt.sh`
4. deploy `fossorial/newt` into k3s using a Kubernetes Secret generated from 1Password

## What Was Renamed
Renamed:
1. `scripts/2-ops/local/` -> `scripts/2-ops/devcontainer/`

Reason:
`local` had become too ambiguous. It could mean:
1. Mac host
2. devcontainer
3. local simulation cluster

`devcontainer` is the clearer label for that disposable k3d/local-lab workflow.

## Small Reliability Improvements
1. `scripts/lib/runbook.sh` gained reusable host-session guards
2. SSH host-key refresh helper was generalized beyond the VPS inventory group
3. `observatory` and `vps` SSH ping scripts now reference host-side reseed scripts on failure
4. `observatory` `01-ansible-ping.sh` was corrected to be a pure reachability check (no `sudo` escalation)

## As Of This Update
These statements were true enough to rely on:
1. `observatory` bootstrap lane works through cluster verification
2. `observatory` has working Debian 12, SSH, sudo, k3s, Helm, label, and cluster verification
3. `pangolin-server` remains the VPS installer/runtime path, not a Kubernetes/Helm path
4. `newt` is now treated as a Kubernetes-native workload on `observatory`
5. Mac host remains the correct home for Pangolin CLI, OP user-session workflows, SSH bootstrap, and secret-writing steps

## Safe Reading Guidance
1. treat inventories, group vars, routes, and scripts as primary truth
2. treat this progress note as the timestamp for the orchestration/docs shape above
3. if a script path and a prose doc disagree, trust the script path and update the doc

## Immediate Next Steps
1. create the `observatory` Pangolin site from the Mac
2. store Newt credentials with `scripts/2-ops/host/10-write-observatory-pangolin-site-secret.sh`
3. run `scripts/2-ops/observatory/02-services/00-run-all.sh`
4. build `11-install-monitoring-stack.sh`
