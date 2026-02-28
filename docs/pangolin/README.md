# Pangolin Reference

This folder is the canonical reference for Pangolin terminology and deployment intent in this repo.

## Files
- `0001-deploy-model.md`: authoritative model for pangolin-server vs cli vs newt, with allowed deployment paths.

## Rule
If a script/playbook change touches Pangolin deployment behavior, update `0001-deploy-model.md` first.

## Current Fact
`newt` has a documented Kubernetes path in the validated docs we use here.

`pangolin-server` does not currently have an obvious first-party Kubernetes deployment path validated in this repo; the active self-host path remains installer/runtime on the VPS.
