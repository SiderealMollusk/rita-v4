# 0660 - Nextcloud Talk Secret Management Tech Debt

Date: 2026-03-05

## Context

Talk/HPB is now functional, but secret handling is still operational debt and not fully lifecycle-managed.

## Current Debt

1. Signaling secret exists in multiple places:
1. Nextcloud Talk signaling registration (`occ talk:signaling:list`)
2. 1Password item (`nextcloud-talk-runtime/password`)
3. HPB server config on `talk-hpb-vm`

2. Rotation is not end-to-end atomic:
1. there is no single script that rotates secret and updates all three targets in one transaction
2. fallback/manual commands are still used during recovery

3. Drift detection is missing:
1. no verify script currently asserts secret parity between Nextcloud and HPB
2. no health gate fails fast on mismatch

4. Repository hygiene risk:
1. plaintext secret exposure was previously possible in runtime YAML and ad-hoc commands
2. policy needs to enforce OP-ref-only for Talk secrets

## Target State

1. One canonical source for secret material: 1Password OP reference only.
2. One rotation workflow that:
1. generates new secret
2. writes OP item
3. updates HPB config + restart
4. updates Nextcloud signaling registration
5. validates websocket + call setup health
3. Verification workflow that checks:
1. signaling endpoint reachable
2. signaling registered in Nextcloud
3. Nextcloud↔HPB secret parity
4. no level>=3 Talk errors in log window after rotation

## Execution Tasks

1. Add `29-rotate-nextcloud-talk-signaling-secret.sh` logic runbook.
2. Add `30-verify-nextcloud-talk-signaling-health.sh` verification runbook.
3. Update `26-configure-nextcloud-talk-runtime.sh` to refuse inline secret values by policy (OP-ref required in managed mode).
4. Add CI/lint guard to reject `talk.signaling.secret` key in `ops/nextcloud/talk-runtime.yaml`.
5. Add rollback step:
1. preserve last-known-good secret in OP item history
2. scripted rollback to prior version.

## Exit Criteria

1. Secret rotation is one-command and idempotent.
2. Secret never appears in git-tracked config or shell history-sensitive docs.
3. Health verify passes after rotation with no manual steps.
