# Platform Requirements

## What You Will Find Here

This directory holds the numbered, lightweight canonical platform requirements.

Start here:
1. `0001-canonical-sources-of-truth.md`
2. `0002-topology-and-lanes.md`
3. `0003-cluster-and-shared-services.md`
4. `0004-exposure-and-edge-model.md`
5. `0005-runbooks-and-operator-boundaries.md`

Use it for:
1. stable platform boundaries
2. current canonical source-of-truth rules
3. lane and placement intent
4. shared-service expectations

## What You Will Not Find Here

Do not use this directory for:
1. detailed rollout plans
2. progress diary material
3. deep implementation specs
4. exploratory product thinking

Those belong in:
1. `docs/plans/`
2. `docs/progress_log/`
3. `docs/prd/`
4. machine-readable truth in `ops/` and `scripts/`

## When And How To Add To This Directory

Add a new numbered requirement when:
1. a platform decision has stabilized enough to be treated as canonical
2. another doc keeps needing to restate the same platform boundary
3. a new major platform area needs a lightweight anchor

When adding:
1. create the next numbered file
2. keep it short and orienting
3. write in terms of stable intent and current truth, not implementation detail

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/requirements/README.md`
2. `docs/system-map.md`
3. relevant runbook READMEs under `scripts/2-ops/`
4. `docs/progress_log/` if the requirement came from newly validated behavior
