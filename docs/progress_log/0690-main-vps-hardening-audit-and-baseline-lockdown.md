# 0690 - Main VPS Hardening Audit And Baseline Lockdown

Date: 2026-03-05
Status: Completed

## Summary
Completed an interactive hardening pass on `main-vps` and captured an audit report.

Applied controls:
1. SSH key-only + root login disabled + reduced auth attack surface
2. fail2ban repaired and active using journald backend
3. unattended security upgrades installed/enabled
4. UFW OpenSSH rate limiting enabled

Audit output is documented in:
1. [0009-main-vps-hardening-audit-2026-03-05.md](/Users/virgil/Dev/rita-v4/docs/research/0009-main-vps-hardening-audit-2026-03-05.md)

## Verification highlights
1. SSH reconnect succeeded after lock-down changes
2. `fail2ban` active with `sshd` jail and active bans
3. `unattended-upgrades` active
4. public endpoint TLS certs valid and security headers present on `cloud.virgil.info`

## Open follow-on
1. add host telemetry layer (`auditd`, AIDE)
2. add Docker daemon hardening baseline and drift checks
3. add recurring security health runbook/automation
