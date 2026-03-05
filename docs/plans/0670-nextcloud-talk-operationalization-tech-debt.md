# 0670 - Nextcloud Talk Operationalization Tech Debt

Date: 2026-03-05

## Context

Talk reliability is improving, but several critical remediations were applied manually on hosts and are not yet encoded as deterministic runbooks.

## Manual Work Performed (Debt)

1. HPB binary was upgraded in place on `talk-hpb-vm` from distro package behavior to upstream runtime.
2. Live Talk signaling endpoint was switched manually in Nextcloud (`occ talk:signaling:*`).
3. Nginx static MIME regressions were remediated through iterative host-level fixes.
4. Nextcloud log backlog was cleared operationally (backup + truncate) to reset stale error counters.

## Why This Is Risky

1. Rebuild/reprovision can revert behavior and reintroduce failures.
2. No single command proves Talk is healthy end-to-end (web join/start, Android video path, signaling).
3. Manual fixes create hidden state drift between git and hosts.
4. Incident response depends on operator memory instead of codified checks.

## Required Runbooks (Missing)

1. `31-install-talk-hpb-runtime.sh`
1. install pinned HPB runtime version
2. install/validate dependencies (janus, nats)
3. configure service and restart safely
4. print runtime version and health endpoint status

2. `32-rotate-talk-signaling-secret.sh`
1. consume canonical OP secret
2. apply to HPB config and Nextcloud signaling registration
3. verify parity and rollback on failure

3. `33-verify-talk-end-to-end.sh`
1. validate signaling endpoint on public HTTPS path
2. validate Nextcloud Talk signaling/stun/turn config
3. validate websocket handshake path reachability
4. fail on MIME regressions (`.mjs`, `.wasm`, css/js/svg/png sanity set)
5. fail on new level>=3 Talk-related server log entries in time window

## Configuration Guardrails (Missing)

1. Nginx policy:
1. no broad `types {}` overrides inside generic static regex locations
2. edge MIME overrides only in narrow dedicated locations (`.mjs`, `.wasm`)

2. Talk signaling policy:
1. canonical signaling URL must be HTTPS same-origin path (no internal `ws://IP` registrations)
2. `verify=true` in managed runtime

3. CI/review checks:
1. lint template for disallowed MIME override patterns
2. lint runtime file for disallowed plaintext secret keys

## Exit Criteria

1. A fresh VM rebuild + scripted apply yields the same working Talk state with no manual host edits.
2. End-to-end verify script passes for web and mobile prerequisites.
3. No undocumented manual commands are required during standard operations.
