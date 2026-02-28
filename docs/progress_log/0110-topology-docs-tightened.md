# 0110 - Topology Docs Tightened
Status: DONE
Date: 2026-02-28

## Summary
The repo topology/access documentation was tightened toward a low-drift model.

The intent is not to create an authoritative prose map that duplicates inventories and routes.
The intent is to leave enough clues that a fresh agent can discover and verify operational truth from canonical machine-readable sources.

## What Changed
Added:
1. `docs/topology.md`
2. `docs/clusters.md`
3. `docs/access-policy.md`
4. `docs/nodes/ops-brain.md`
5. `docs/nodes/platform-node.md`
6. `docs/nodes/workload-node.md`

Updated:
1. `docs/system-map.md`
2. `docs/lab-nodes.md`

## Documentation Style Decision
The repo now prefers:
1. short clue docs
2. direct links to inventories, routes, group vars, and runbooks
3. verification tips instead of duplicated operational state

The repo now avoids:
1. copying IPs into multiple files
2. repeating routes in prose docs
3. over-claiming authoritative state where machine-readable files should be primary

## As Of This Update
These statements were true and verified strongly enough to document:
1. `main-vps` exists and runs `pangolin-server` as the public edge runtime.
2. `ops-brain` exists and has a working k3s control plane bootstrap path from repo automation.
3. `ops-brain` and `main-vps` are separate operational domains.
4. `platform-node` and `workload-node` remain planned role definitions, not yet fully installed/validated nodes in repo automation.
5. `ops/ansible/inventory/*.ini` and `ops/network/routes.yml` are the canonical discovery sources for hosts and externally hittable routes.

## How To Read These Docs Safely
1. Use the docs to find the right source file or runbook.
2. Use inventories, routes, group vars, and scripts as primary truth.
3. Use progress logs as an implicit timestamp for how trustworthy a summary doc is likely to be.
4. If a doc and a machine-readable source disagree, trust the machine-readable source and update the doc.

## Next Useful Verification Upgrades
1. add future inventory entries for `platform-node` and `workload-node` once real hosts exist
2. add a stronger service contact matrix once monitoring services are live
3. add more explicit Pangolin/Newt route verification once `ops-brain` site registration is automated
