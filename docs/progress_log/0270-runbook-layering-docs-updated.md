# 0270 Runbook Layering Docs Updated

As of this update, the repo docs were tightened to describe the actual ordered capacities and privilege boundaries that have emerged during implementation.

## What was clarified

1. `host` is now explicitly documented as the smallest operator-boundary lane:
   - bootstrap identity
   - write secrets
   - apply Pangolin mutations with host-held auth
2. `devcontainer` is the reproducible validation/automation lane
3. `ops-brain` is documented as an ordered service lane:
   - bootstrap host
   - bootstrap cluster
   - connect Newt
   - install monitoring
   - verify site-perspective reachability
4. Pangolin resource exposure is documented as a later declarative layer, not part of bootstrap

## Why this matters

This reduces ambiguity about where actions belong:
1. if the privilege lives on the host, the action belongs in `scripts/2-ops/host/`
2. if the action is reproducible repo automation, it belongs in the devcontainer or target-specific runbooks
3. if the action exposes services through Pangolin, it should be treated as a resource-layer change, not infrastructure bootstrap

## Reading habit

Use this note plus the latest relevant progress note as the practical timestamp before trusting the clue docs:
1. `/Users/virgil/Dev/rita-v4/docs/system-map.md`
2. `/Users/virgil/Dev/rita-v4/docs/access-policy.md`
3. `/Users/virgil/Dev/rita-v4/docs/topology.md`
