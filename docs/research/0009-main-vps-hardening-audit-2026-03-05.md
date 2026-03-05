# 0009 - Main VPS Hardening Audit (2026-03-05)
Date: 2026-03-05
Status: Completed snapshot

## Scope
Audit the public VPS (`main-vps` / `public-edge`) after baseline hardening changes.

Target:
1. host: `159.195.41.160`
2. user: `virgil`
3. OS: Debian 12 (bookworm)

## Commands and evidence summary

### Host and base runtime
Observed:
1. Debian 12, kernel `6.1.0-43-amd64`
2. active services include `ssh`, `ufw`, `docker`, `fail2ban`, `unattended-upgrades`

### SSH hardening state (effective)
Effective `sshd -T` values:
1. `permitrootlogin no`
2. `passwordauthentication no`
3. `pubkeyauthentication yes`
4. `kbdinteractiveauthentication no`
5. `x11forwarding no`
6. `maxauthtries 3`
7. `logingracetime 30`
8. `clientaliveinterval 300`
9. `clientalivecountmax 2`
10. `allowusers virgil`

### Fail2ban state
1. service is enabled and active
2. jail loaded: `sshd`
3. initial failure root cause was fixed (`auth.log` assumption on systemd-journald host)
4. current status snapshot:
   - currently failed: `2`
   - total failed: `64`
   - currently banned: `6`

### Firewall state
1. UFW active; default incoming policy deny
2. OpenSSH switched to `LIMIT`
3. fail2ban reject rules present for banned source IPs
4. iptables chain state confirms UFW integration and Docker chains

### External header and TLS posture
`https://cloud.virgil.info`:
1. HSTS present (`max-age=15552000; includeSubDomains`)
2. CSP, X-Frame-Options, X-Content-Type-Options present
3. cert issuer: Let's Encrypt `R12`
4. cert window: `2026-03-04` to `2026-06-02`

`https://pangolin.virgil.info`:
1. cert issuer: Let's Encrypt `R12`
2. cert window: `2026-02-27` to `2026-05-28`

## Key findings

### High priority findings
1. Active internet SSH brute-force traffic is constant (multiple invalid-user/root attempts in recent logs).
2. Docker publishes public ports `80/443` and UDP `51820/21820`; this is expected for Pangolin stack but should be treated as high-value exposed surface.

### Medium priority findings
1. Docker socket is not accessible to `virgil` without elevation in current session (good for least privilege), but daemon hardening should still be verified explicitly.
2. `AllowUsers virgil` is in place; if additional admin users are added later, this file must be intentionally maintained.

### Lower priority findings
1. Additional host telemetry controls (`auditd`, AIDE, Lynis) were not present at audit time.

## Changes already applied in this hardening session
1. Added SSH lock-down config at `/etc/ssh/sshd_config.d/99-hardening.conf`
2. Added fail2ban jail override at `/etc/fail2ban/jail.d/sshd.local` using `backend=systemd`
3. Installed and enabled `unattended-upgrades`
4. Enabled UFW OpenSSH rate limiting

## Recommended next hardening wave
1. Add `auditd` and minimal immutable audit rules for auth/sudo/systemd/service changes.
2. Add file integrity monitoring (`AIDE`) for `/etc`, systemd unit paths, and SSH/fail2ban config.
3. Pin and document Docker daemon configuration (`/etc/docker/daemon.json`), confirm no TCP daemon socket (`2375/2376`) and enforce log rotation.
4. Add an operator runbook for periodic checks:
   - certificate expiry lead time
   - fail2ban jail health
   - UFW drift
   - pending security updates
5. Add threat-driven monitoring for repeated `sshd` attacks and suspicious successful logins.

## Related docs
1. [0005-systemd-templates-ai-workers.md](/Users/virgil/Dev/rita-v4/docs/research/0005-systemd-templates-ai-workers.md)
2. [main-vps node reference](/Users/virgil/Dev/rita-v4/docs/nodes/main-vps.md)
