# Pangolin Reference

This folder is the canonical reference for Pangolin terminology and deployment intent in this repo.

## Files
- `0001-deploy-model.md`: authoritative model for pangolin-server vs cli vs newt, with allowed deployment paths.
- `0002-human-site-registration.md`: human/operator bootstrap flow for Pangolin site creation and Newt credential capture.

## Rule
If a script/playbook change touches Pangolin deployment behavior, update `0001-deploy-model.md` first.

For Pangolin-managed resource exposure on `ops-brain`, also use:
1. [0150-pangolin-resource-management-for-ops-brain.md](/Users/virgil/Dev/rita-v4/docs/plans/0150-pangolin-resource-management-for-ops-brain.md)
2. [0250-pangolin-resource-layer-started.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0250-pangolin-resource-layer-started.md)

## Current Fact
`newt` has a documented Kubernetes path in the validated docs we use here.

`pangolin-server` does not currently have an obvious first-party Kubernetes deployment path validated in this repo; the active self-host path remains installer/runtime on the VPS.
