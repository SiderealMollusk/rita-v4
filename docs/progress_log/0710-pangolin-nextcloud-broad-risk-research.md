# 0710 - Pangolin + Nextcloud Broad Risk Research

Date: 2026-03-05
Status: Completed

## Summary
Completed a broad sweep of Pangolin + Nextcloud integration failure modes using official docs and issue trackers, focused on preventing random regressions/outages.

Output:
1. [0012-pangolin-nextcloud-integration-risk-register.md](/Users/virgil/Dev/rita-v4/docs/research/0012-pangolin-nextcloud-integration-risk-register.md)

## Coverage
1. auth/rule ordering and bypass risk
2. proxy/header trust and brute-force side-effects
3. `/.well-known` + DAV/OCS path reliability
4. websocket/realtime dependencies (`notify_push`, Talk HPB, Office)
5. ExApp daemon and `/exapps/` routing
6. Pangolin version/regression handling
