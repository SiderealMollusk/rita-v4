# 0012 - Pangolin + Nextcloud Integration Risk Register (Broad Sweep)
Date: 2026-03-05
Status: Active research note

## Scope
Broadly map common failure modes when running Nextcloud behind Pangolin and provide preemptive controls/checks to avoid "random crap" outages.

## Executive view
Most Pangolin + Nextcloud incidents cluster around:
1. auth layering and rule order
2. reverse-proxy/header correctness
3. path routing for Nextcloud protocol endpoints
4. websocket/real-time channels (Talk, notify_push, Office)
5. ExApp deploy-daemon and `/exapps/` routing
6. version/regression risk in Pangolin components

## Risk classes and proactive controls

### R1) Auth bypass or unexpected access due to Pangolin rule configuration
Why:
1. Pangolin rules can explicitly bypass auth and are priority-ordered top-to-bottom.
2. Pangolin docs include broad path matching and bypass options that can accidentally over-match.
3. There is at least one open Pangolin issue reporting auth bypass behavior when resource rules are enabled in a specific version.

Controls:
1. Treat `Bypass Auth` rules as privileged changes and code-review them.
2. Default to `Pass to Auth` and narrow path/CIDR matches.
3. Keep a deny rule for sensitive paths (admin-only paths).
4. Add canary tests (incognito + unauthenticated endpoint probes) after each rule change.

Sources:
1. Pangolin Rules (processing order, bypass/block/pass): https://docs.pangolin.net/manage/access-control/rules
2. Pangolin public resource auth defaults: https://docs.pangolin.net/manage/resources/public/authentication
3. Pangolin issue (auth ineffective with rules): https://github.com/fosrl/pangolin/issues/1679

### R2) Breaking Nextcloud clients by gating wrong endpoints
Why:
1. Nextcloud uses multiple protocol/API paths beyond `/` (`/remote.php/*`, `/ocs/*`, `/.well-known/*`, etc.).
2. If Pangolin auth/rules block or incorrectly bypass these, desktop/mobile/WebDAV/CalDAV behavior degrades.

Controls:
1. Build explicit allow/auth path policies for Nextcloud-required endpoints.
2. Test login, WebDAV, CalDAV/CardDAV, OCS API, share links, and app-store/app API endpoints after changes.

Sources:
1. Pangolin rules page includes Nextcloud path examples: https://docs.pangolin.net/manage/access-control/rules
2. Nextcloud reverse-proxy + service discovery requirements: https://docs.nextcloud.com/server/24/admin_manual/configuration_server/reverse_proxy_configuration.html

### R3) Nextcloud brute-force throttling all users due to proxy header misconfig
Why:
1. If `trusted_proxies` / `forwarded_for_headers` are wrong, Nextcloud may see proxy IP as all clients.
2. This can trigger global login slowness/throttling and useless audit attribution.

Controls:
1. Keep strict proxy IP allowlist in `trusted_proxies`.
2. Set only correct forwarded header names for your proxy chain.
3. Validate detected client IPs in logs after each proxy change.

Sources:
1. Nextcloud reverse proxy docs: https://docs.nextcloud.com/server/24/admin_manual/configuration_server/reverse_proxy_configuration.html
2. Nextcloud brute-force docs (reverse proxy warning): https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/bruteforce_configuration.html
3. Nextcloud config parameters warning on spoofing risk: https://docs.nextcloud.com/server/31/admin_manual/configuration_server/config_sample_php_parameters.html

### R4) `/.well-known` and DAV discovery regressions
Why:
1. Reverse proxies must redirect CalDAV/CardDAV discovery correctly.
2. Misroutes show up as Nextcloud admin warnings and client sync weirdness.

Controls:
1. Implement `/.well-known/caldav` and `/.well-known/carddav` redirects at proxy layer.
2. Add continuous probe checks for those redirects.

Sources:
1. Nextcloud reverse proxy service discovery examples: https://docs.nextcloud.com/server/24/admin_manual/configuration_server/reverse_proxy_configuration.html
2. Nextcloud admin warnings doc: https://docs.nextcloud.com/server/31/admin_manual/configuration_server/security_setup_warnings.html

### R5) Real-time features failing from websocket/reverse-proxy gaps
Why:
1. `notify_push` needs websocket-compatible reverse proxying and exact path behavior.
2. Talk HPB and Office also depend on websocket/correct proxy route handling.

Controls:
1. Keep explicit websocket forwarding config for `/push/` and other realtime paths.
2. Run app-provided setup/self-tests after updates.
3. Track websocket failures in logs as first-class alerts.

Sources:
1. notify_push README reverse-proxy config: https://github.com/nextcloud/notify_push
2. Nextcloud Talk quick install (HPB): https://nextcloud-talk.readthedocs.io/en/stable/quick-install/
3. Nextcloud Office proxy routes: https://docs.nextcloud.com/server/latest/admin_manual/office/proxy.html

### R6) Upload/download failures under layered proxies
Why:
1. Large file operations are sensitive to proxy buffering, body limits, temp storage, and timeouts.
2. Multi-proxy setups can silently cap transfer behavior.

Controls:
1. Align Nginx/PHP/Nextcloud upload limits and temp paths.
2. Explicitly review proxy buffering/timeouts in front of Nextcloud.
3. Include large-file synthetic tests in post-change checks.

Sources:
1. Nextcloud big upload tuning: https://docs.nextcloud.com/server/29/admin_manual/configuration_files/big_file_upload_configuration.html
2. Nextcloud Nginx baseline: https://docs.nextcloud.com/server/26/admin_manual/installation/nginx.html

### R7) ExApps unstable because deploy daemon/routing not fully aligned
Why:
1. AppAPI requires deploy daemon correctness plus route wiring.
2. Newer guidance prefers HaRP and requires `/exapps/` routing adjustments.

Controls:
1. Standardize one daemon mode (HaRP preferred unless intentionally deferred).
2. Verify daemon with AppAPI "Test Deploy".
3. Validate `/exapps/` routing end-to-end after updates.

Sources:
1. AppAPI and external apps: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/AppAPIAndExternalApps.html
2. Deployment configurations: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/DeployConfigurations.html
3. HaRP repo/docs: https://github.com/nextcloud/HaRP

### R8) Pangolin version/regression churn
Why:
1. Issue tracker shows recurring reports around networking, startup regressions, and bad gateway behavior.
2. Even when fixed later, upgrades can surface transient breakage.

Controls:
1. Stage updates and keep known-good rollback artifacts.
2. Run canary tests before/after Pangolin upgrades.
3. Pin versions during stability windows.

Sources:
1. Representative Pangolin issues:
- https://github.com/fosrl/pangolin/issues/1711
- https://github.com/fosrl/pangolin/issues/1070
- https://github.com/fosrl/pangolin/issues/1006
- https://github.com/fosrl/pangolin/issues/900

## Preemptive canary test set (run after every proxy/auth change)
1. anonymous GET `/status.php` (expected policy)
2. authenticated web login + logout
3. WebDAV PROPFIND `/remote.php/dav/files/<user>/`
4. CalDAV/CardDAV discovery redirects from `/.well-known/*`
5. OCS API response from `/ocs/v2.php/...`
6. `notify_push` health/setup test
7. Talk call setup + ring/answer/terminate state
8. one large upload/download (>1GB)
9. ExApp health if AppAPI is enabled (`/exapps/` path)

## Operational recommendations for your environment
1. Keep protected-resource auth enabled, but explicitly model machine/API paths separately.
2. Avoid broad Pangolin bypass rules for Nextcloud; prefer narrow path/CIDR rules.
3. Keep Nextcloud proxy identity settings (`trusted_proxies`, `forwarded_for_headers`) under strict change control.
4. Treat Pangolin upgrades as change windows with rollback and canary checks, not in-place blind updates.
