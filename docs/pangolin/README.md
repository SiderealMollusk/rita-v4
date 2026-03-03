# Pangolin Reference

## What You Will Find Here

This directory is the canonical numbered reference for Pangolin and Newt deployment intent in this repo.

Files:
1. `0001-deploy-model.md`
2. `0002-human-site-registration.md`

Use it for:
1. Pangolin/Newt terminology
2. deployment-path rules
3. site registration expectations
4. edge/exposure reference material

## What You Will Not Find Here

Do not use this directory for:
1. live operational status
2. resource-by-resource rollout progress
3. step-by-step implementation plans for unrelated services
4. generic networking requirements outside Pangolin/Newt

Those belong in:
1. `docs/progress_log/`
2. `docs/plans/`
3. `docs/requirements/platform/`

## When And How To Add To This Directory

Add a new numbered file when:
1. Pangolin/Newt behavior needs a stable reference note
2. a new deployment rule or registration model becomes canonical
3. terminology needs to be clarified to prevent drift

When adding:
1. create the next numbered note
2. keep it reference-oriented, not diary-style
3. update this README if the new file changes the entry points or scope

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/requirements/platform/0004-exposure-and-edge-model.md`
2. `docs/system-map.md`
3. relevant runbook READMEs under `scripts/2-ops/`
4. `docs/progress_log/` if the note reflects a newly validated live edge behavior

## Current Fact

`newt` has a documented Kubernetes path in the validated docs we use here.

`pangolin-server` does not currently have an obvious first-party Kubernetes deployment path validated in this repo; the active self-host path remains installer/runtime on the VPS.
