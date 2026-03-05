# 0730 - Nextcloud Warning State After HPB Stabilization

Date: 2026-03-05

## Summary

HPB runtime is now script-driven and healthy, but Nextcloud admin warnings remain in several non-HPB areas.

Observed warning snapshot after HPB stabilization includes:
1. Brute-force throttle for IP `23.93.227.242`
2. PDO SQLite driver missing
3. Errors in log
4. Mimetype migrations available
5. Missing DB indices
6. No second factor provider
7. PHP getenv warning
8. AppAPI default deploy daemon not set
9. Font file loading check
10. Email test not configured
11. Recording backend not configured
12. SIP backend not configured

## What Was Confirmed

1. `23.93.227.242` is not random proxy drift evidence by itself:
1. Nextcloud logs show repeated auth failures for user `quell` from Android Talk user-agent (`Nextcloud-Talk v23.0.0`).
2. This maps to stale mobile credentials/retries causing brute-force throttle.

2. `PDO SQLite` warning was a real automation gap:
1. `php-sqlite3` was missing from managed package list in Nextcloud group vars.
2. This has now been added to desired state in:
- [nextcloud.yml](/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/nextcloud.yml)

## Operational Interpretation

1. HPB is now functionally online, but overall admin warning count still includes:
1. expected/not-yet-enabled features (2FA, SMTP, recording/SIP, AppAPI daemon default),
2. maintenance debt (mimetype repair, db indices),
3. noisy operational artifacts (log backlog, brute-force throttles from stale clients).

2. Current state should be treated as:
1. HPB lane stabilized,
2. admin-warning remediation not yet complete.

## Next Step

Execute the dedicated warning burn-down plan:
- [0700-nextcloud-admin-warning-burndown-execution.md](/Users/virgil/Dev/rita-v4/docs/plans/0700-nextcloud-admin-warning-burndown-execution.md)
