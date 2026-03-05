# 0620 - Nextcloud Admin Overview Post-Remediation Snapshot

Date: 2026-03-05

## Summary

Captured the current Nextcloud Administration -> Overview warning state after:
1. reverse proxy/header/MIME remediation
2. DB index + expensive repair maintenance

Most P0/P1 platform correctness warnings are now closed. Remaining warnings are feature/integration gaps.

## Remaining Warnings (Current)

1. PDO SQLite driver missing (Collectives full-text search)
2. High-performance backend not configured (Talk)
3. Errors in the log (2 errors since 2026-02-25 20:10:16)
4. No second factor provider available
5. PHP `getenv("PATH")` warning
6. Client Push not installed
7. AppAPI default deploy daemon not set
8. Font file loading self-check failed (`.otf`)
9. Email server not configured/tested

## Closed Since Earlier Baseline

1. `.mjs` JavaScript MIME warning
2. Reverse proxy forwarded header warning
3. OCS provider resolving warning
4. HSTS warning
5. PHP memory limit warning
6. Maintenance window warning
7. Default phone region warning
8. Mimetype migration warning
9. Missing DB indices warning

## Execution Notes

1. A transient MIME regression was introduced during remediation (CSS/JS returned `application/octet-stream`) and then corrected by narrowing Nginx location MIME handling.
2. Current endpoint checks confirm:
- CSS returns `text/css`
- JS/MJS return `application/javascript`
- `/ocs-provider/` returns JSON as expected

## Next Action Order

1. Install SQLite PHP extension for Collectives search
2. Configure Talk reliability stack (`HPB`, `STUN/TURN`, `notify_push`)
3. Enable at least one 2FA provider for admins
4. Decide and implement FPM env strategy for `getenv("PATH")`
5. Configure SMTP + send test mail
