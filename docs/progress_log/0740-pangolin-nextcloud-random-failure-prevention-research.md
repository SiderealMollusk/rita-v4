# 0740 - Pangolin + Nextcloud Random Failure Prevention Research

Date: 2026-03-05
Status: Completed

## Summary
Produced a broad, prevention-focused risk sweep for Pangolin + Nextcloud with ranked failure classes, concrete controls, canary checks, and upstream references.

Output:
1. [0013-pangolin-nextcloud-random-failure-prevention-2026-03-05.md](/Users/virgil/Dev/rita-v4/docs/research/0013-pangolin-nextcloud-random-failure-prevention-2026-03-05.md)

## Coverage
1. auth/rule ordering and bypass risk
2. reverse proxy identity and brute-force throttling pitfalls
3. path/protocol regressions (`/.well-known`, DAV, OCS)
4. websocket/realtime dependencies (Talk, notify_push, Office)
5. ExApps deploy-daemon topology drift and HaRP guidance
6. large upload/timeout and buffering failure class
7. upgrade/regression management for Pangolin
8. tunnel and network edge-case instability patterns

## Method
1. Cross-checked Pangolin official docs, Nextcloud admin docs, and upstream issue trackers.
2. Distinguished high-confidence (official docs) vs medium-confidence (issue-pattern) findings.
3. Converted findings into concrete runbook-style prevention checks.
