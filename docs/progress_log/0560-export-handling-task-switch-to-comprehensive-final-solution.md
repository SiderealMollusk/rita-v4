# 0560 - Export Handling Task Switch To Comprehensive Final Solution

Date: 2026-03-04

## Task Switch

This thread is explicitly switching away from one-off fixes for the Nextcloud VM bring-up and into a **COMPREHENSIVE FINAL SOLUTION** for repo-wide export/env handling.

Reason:
1. the active operator path still leaked too much shell state
2. the new `op`-first runbooks were not fully aligned with the repo's existing `OP_SERVICE_ACCOUNT_TOKEN` reality
3. the install path for `nextcloud-core` proved that the helper layer was still forcing manual workarounds in cases where the repo should already be "basically wired"

## Trigger For The Switch

Live state at the moment of the switch:
1. `nextcloud-core` VM host bootstrap succeeded on `192.168.6.183`
2. `12-install-nextcloud-core.sh` did **not** complete
3. the immediate blocker was not Nextcloud itself, but the runbook helper behavior:
   - the script wanted to resolve secrets from 1Password
   - the shared helper rejected service-account mode
   - that forced a bad workaround pattern involving manual secret exports

That workaround pattern is now considered unacceptable for the canonical operator story.

## New Goal

The canonical repo behavior should be:
1. clone repo on a new machine
2. `direnv allow`
3. authenticate `op` in whichever supported mode is available
4. run named runbooks

It should **not** require repeated manual exports of:
1. `KUBECONFIG`
2. admin passwords
3. database passwords
4. other secret values that the repo already knows how to resolve from `op://...`

## What Must Be True After This Cleanup

1. secret-reading runbooks accept either:
   - human `op signin`, or
   - `OP_SERVICE_ACCOUNT_TOKEN`
2. manual secret exports are fallback-only, not part of the normal operator path
3. `.envrc` and shared runbook helpers define the repo-wide env-loading pattern
4. the new Nextcloud VM path becomes effectively zero-export for normal use
5. docs stop implying that the operator should prepare shell state manually when the repo can derive it itself

## Resume Point

When this cleanup is complete, resume the live Nextcloud VM bring-up here:
1. rerun [12-install-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/12-install-nextcloud-core.sh)
2. run [13-verify-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/13-verify-nextcloud-core.sh)
3. record a fresh progress note for the successful `nextcloud-core` install baseline

## Scope Of The Cleanup Pass

This pass should normalize:
1. shared `op` helper behavior in [runbook.sh](/Users/virgil/Dev/rita-v4/scripts/lib/runbook.sh)
2. active workload and host runbooks that still duplicate `.labrc`, `KUBECONFIG`, or `op` auth assumptions
3. docs that still describe the operator story in terms of remembered exports

Historical logs should remain historical unless they are actively misleading current operators.
