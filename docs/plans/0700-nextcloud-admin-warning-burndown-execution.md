# 0700 - Nextcloud Admin Warning Burndown Execution

Date: 2026-03-05
Status: Active

## Goal

Drive Nextcloud admin warnings from mixed state to intentional state (`done` or `accepted_risk`) using scripted, repeatable steps.

## Scope

Official instance:
1. `cloud.virgil.info`
2. Host: `nextcloud-vm` (`192.168.6.183`)
3. Talk HPB host: `talk-hpb-vm` (`192.168.6.184`)

## Warning Groups

### Group A - Immediate correctness and noise control

1. Brute-force throttle
2. PDO SQLite driver
3. Errors in the log

### Group B - Core maintenance and performance

1. Mimetype migrations available
2. Missing DB indices

### Group C - Security and platform policy

1. Second factor provider
2. PHP getenv
3. AppAPI default deploy daemon

### Group D - Optional integrations / accepted risk candidates

1. Font file loading check
2. Email test
3. Recording backend
4. SIP backend

## Execution Plan

### Phase 1 - Stabilize baseline warnings

1. Apply package fix for SQLite:
```bash
cd /Users/virgil/Dev/rita-v4
NEXTCLOUD_SNAPSHOT_MODE=off ./scripts/2-ops/workload/12-install-nextcloud-core.sh
```

2. Reset known brute-force offender (after fixing stale client creds):
```bash
ssh virgil@192.168.6.183 "sudo -u www-data php /var/www/nextcloud/occ security:bruteforce:reset 23.93.227.242"
```

3. Verify sqlite module on host:
```bash
ssh virgil@192.168.6.183 "php -m | grep -Ei 'sqlite|pdo_sqlite'"
```

Exit criteria:
1. `PDO SQLite` warning cleared.
2. Brute-force warning either cleared or known to reappear only with bad client credentials.

### Phase 2 - Run safe maintenance debt cleanup

1. Add missing indices:
```bash
ssh virgil@192.168.6.183 "sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices"
```

2. Run mimetype repair:
```bash
ssh virgil@192.168.6.183 "sudo -u www-data php /var/www/nextcloud/occ maintenance:repair --include-expensive"
```

Exit criteria:
1. DB indices warning cleared.
2. Mimetype migrations warning cleared.

### Phase 3 - Security and app-platform decisions

1. Second factor provider:
1. enable at least one provider app (TOTP recommended),
2. confirm availability in admin security panel.

2. AppAPI default daemon:
1. ensure daemon registration and default selection are scripted/verified for VM path.

3. PHP getenv:
1. decide policy (`accepted_risk` vs remediation in PHP-FPM env handling),
2. document final decision.

Exit criteria:
1. each of the three items is either `done` or explicitly `accepted_risk` with rationale.

### Phase 4 - Optional service integrations

1. Email SMTP config and test
2. Recording backend
3. SIP backend
4. Font self-check (or document accepted risk)

Exit criteria:
1. each item resolved or accepted risk documented in progress note.

## Verification Loop (per phase)

After each phase:
1. refresh Nextcloud admin warnings page,
2. capture delta in new progress note,
3. keep unresolved items with owner + next action.

## Suggested Progress Note Sequence

1. `0740` - Group A completion
2. `0750` - Group B completion
3. `0760` - Group C decisions/fixes
4. `0770` - Group D resolution or accepted-risk closure

## Dependencies / Risks

1. Brute-force warning can recur from stale mobile credentials even with correct proxy setup.
2. Maintenance commands can take time on larger datasets; run during low usage.
3. AppAPI and ExApp warnings may fluctuate while Flow/ExApp runtime is intentionally incomplete.
