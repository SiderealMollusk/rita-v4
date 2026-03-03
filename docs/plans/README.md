# Plans

## What You Will Find Here

This directory holds numbered execution and sequencing plans.

Use it for:
1. phased work plans
2. migration or rollout sequencing
3. dependency ordering
4. actionable implementation guidance that is still lighter than a full runbook

## What You Will Not Find Here

Do not use this directory for:
1. canonical architecture requirements
2. pure product concept exploration
3. validated live status
4. low-level script or manifest truth

Those belong in:
1. `docs/requirements/`
2. `docs/prd/`
3. `docs/progress_log/`
4. `ops/` and `scripts/`

## When And How To Add To This Directory

Add a new numbered plan when:
1. a workstream needs explicit phases or sequencing
2. there is enough clarity to guide implementation
3. the work is not yet validated enough for a progress note

When adding:
1. create the next numbered file
2. keep the plan ordered and action-oriented
3. avoid duplicating stable requirements unless the plan depends on them

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/requirements/` if the plan reveals a stable architectural or product decision
2. `docs/system-map.md` if the new plan becomes a current entry point
3. `docs/progress_log/` once the planned work is validated
4. relevant runbook READMEs if operator flow changes
