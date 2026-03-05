# 0013 - Pangolin + Nextcloud: Broad Issue Sweep and Random-Failure Prevention
Date: 2026-03-05
Status: Completed

## Goal
Identify the most common and highest-impact failure patterns when Nextcloud is fronted by Pangolin, then define preemptive controls so outages/regressions are caught before users hit them.

## What breaks most often (ranked)

### 1) Access-control/rule mistakes create accidental open access or hard lockout
Why this is common:
1. Pangolin rules are powerful and are evaluated in priority order.
2. `Bypass Auth` rules can over-match, especially with wildcards and broad paths.
3. There has been a reported auth-bypass behavior tied to rules in Pangolin v1.11.0.

What to do:
1. Treat any `Bypass Auth` change as a security change requiring review.
2. Prefer `Pass to Auth` defaults and narrow allowlists.
3. Add explicit deny paths for admin/sensitive endpoints.
4. Run unauthenticated/incognito canaries after every rule edit.

### 2) Client IP/proxy identity mistakes trigger global brute-force throttling
Why this is common:
1. Nextcloud relies on correct proxy identity (`trusted_proxies`, `forwarded_for_headers`).
2. If wrong, all login attempts may appear from one proxy IP.

What to do:
1. Keep a strict proxy-IP allowlist in Nextcloud.
2. Verify real client IP appears in logs after any proxy/network change.
3. Never combine broad forwarded-header trust with untrusted hops.

### 3) Missing path exceptions break DAV/CalDAV/CardDAV/mobile/API flows
Why this is common:
1. Nextcloud depends on more than `/`.
2. `/.well-known` redirects and `/remote.php/*` are frequent regression points.

What to do:
1. Validate endpoint coverage for `/remote.php/dav`, `/ocs/v1.php`, `/ocs/v2.php`, `/.well-known/*`, `/status.php`.
2. Keep explicit tests for DAV discovery redirects.

### 4) Realtime channels fail (Talk, notify_push, Office websockets)
Why this is common:
1. Realtime components need websocket-friendly proxying and path routing.
2. Talk media requires STUN/TURN for cross-network/mobile reliability.

What to do:
1. Include websocket probes for push/office/talk paths in post-change checks.
2. Validate TURN/STUN in Talk (especially mobile network scenarios).
3. Treat call setup/ringing as a release gate, not a manual spot-check.

### 5) ExApps instability from deploy-daemon topology drift
Why this is common:
1. AppAPI supports multiple deployment modes; mismatches are easy.
2. HaRP is now a primary path and remote/GPU deployments add moving parts.

What to do:
1. Standardize one deploy model per environment (prefer HaRP unless intentionally deferred).
2. Run AppAPI "Test deploy" as a required health check.
3. Keep `/exapps/` route checks in your canary suite.

### 6) Upload/download timeouts and partial transfers under layered proxies
Why this is common:
1. Large files stress body-size limits, buffering, temp storage, and timeouts.
2. Multi-proxy chains can impose hidden limits.

What to do:
1. Align upload/timeouts across frontend proxy, app proxy, web server, and PHP.
2. Track large-file synthetic transfer as a standard reliability test.

### 7) Pangolin upgrade/regression churn
Why this is common:
1. Field issues show periodic regressions around auth, networking, and startup.
2. In-place upgrades without canaries make rollback harder.

What to do:
1. Stage upgrades; pin known-good versions.
2. Follow incremental upgrades between major versions.
3. Keep rollback artifact backups (`config` + compose versions) ready before upgrades.

### 8) Tunnel/network edge cases (Newt/WireGuard paths)
Why this is common:
1. Pangolin requires specific TCP/UDP exposure and stable tunnel connectivity.
2. Incorrect firewall/NAT behavior causes intermittent tunnel failures.

What to do:
1. Continuously verify required ports and tunnel handshake health.
2. Alert on Newt reconnect loops and wireguard ping loss.

## "Random crap" prevention framework

### A) Change-gating policy
1. No Pangolin rule edits in production without a canary run.
2. No Pangolin upgrades without backup + canary + rollback plan.
3. No Nextcloud auth/proxy config changes without login + DAV + OCS verification.

### B) Canary pack (10 checks, automated)
1. Anonymous access behavior on `/status.php` matches intended policy.
2. Interactive web login/logout succeeds.
3. WebDAV PROPFIND succeeds for a test user.
4. `/.well-known/caldav` and `/.well-known/carddav` redirect correctly.
5. `/ocs/v2.php` responds as expected.
6. `notify_push` setup/health check passes.
7. Talk call test: setup -> ring -> join -> hangup.
8. Office route test including websocket endpoint.
9. ExApps test deploy and sample ExApp health.
10. Large upload/download synthetic test (>1 GB).

### C) Observability triggers
1. Alert on spikes in 401/403/429, especially after config changes.
2. Alert on 502/504 at Pangolin/Traefik edge.
3. Alert on websocket upgrade failures.
4. Alert on Nextcloud warnings related to reverse proxy/brute-force/security setup.

## Priority actions for your environment (next 7 days)
1. Freeze Pangolin/Traefik versions until canary automation is always-on.
2. Add a single script that runs the 10 canary checks before/after every change.
3. Add a "rules audit" checklist for each resource (especially bypass rules).
4. Add scheduled verification of Nextcloud proxy identity correctness.
5. Add one monthly update window with explicit rollback checkpoints.

## Sources
1. Pangolin Rules: https://docs.pangolin.net/manage/access-control/rules
2. Pangolin resource authentication defaults: https://docs.pangolin.net/manage/resources/public/authentication
3. Pangolin forwarded headers: https://docs.pangolin.net/manage/access-control/forwarded-headers
4. Pangolin DNS/networking and required ports: https://docs.pangolin.net/self-host/dns-and-networking
5. Pangolin update process and incremental version guidance: https://docs.pangolin.net/self-host/how-to-update
6. Pangolin changelog pointer: https://docs.pangolin.net/additional-resources/changelog
7. Nextcloud reverse proxy configuration: https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/reverse_proxy_configuration.html
8. Nextcloud brute-force configuration: https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/bruteforce_configuration.html
9. Nextcloud security/setup warnings: https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/security_setup_warnings.html
10. Nextcloud notify_push (reverse proxy setup/tests): https://github.com/nextcloud/notify_push
11. Nextcloud Talk quick install (STUN/TURN): https://nextcloud-talk.readthedocs.io/en/stable/quick-install/
12. Nextcloud Office reverse proxy endpoints: https://docs.nextcloud.com/server/stable/admin_manual/office/proxy.html
13. Nextcloud AppAPI external apps: https://docs.nextcloud.com/server/stable/admin_manual/exapps_management/AppAPIAndExternalApps.html
14. Nextcloud AppAPI deployment configs (HaRP, test deploy): https://docs.nextcloud.com/server/stable/admin_manual/exapps_management/DeployConfigurations.html
15. HaRP project: https://github.com/nextcloud/HaRP
16. Pangolin issue: rules/auth interaction report (#1679): https://github.com/fosrl/pangolin/issues/1679
17. Pangolin issue: bad gateway on resource add (#1070): https://github.com/fosrl/pangolin/issues/1070
18. Pangolin issue: Newt connectivity instability report (#951): https://github.com/fosrl/pangolin/issues/951
19. Pangolin issue: update crash regression report (#900): https://github.com/fosrl/pangolin/issues/900
20. Pangolin issue: intermittent container connectivity report (#1711): https://github.com/fosrl/pangolin/issues/1711

## Notes on confidence
1. High confidence: official Pangolin/Nextcloud docs and config guidance.
2. Medium confidence: issue-tracker patterns (real-world signal, but environment-specific and sometimes unresolved).
