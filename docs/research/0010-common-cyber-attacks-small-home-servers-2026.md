# 0010 - Common Cyber Attacks Against Small Home Servers (2026)
Date: 2026-03-05
Status: Active research note

## Scope
Identify the attack patterns most relevant to small self-hosted internet-exposed servers and map them to practical defensive controls.

## High-frequency attack patterns

### 1) Credential attacks on remote services (especially SSH)
Why common:
1. Continuous internet-wide brute force/password spraying on SSH and admin panels.
2. MITRE maps brute force as a common technique for initial/credential access.

Evidence for this environment:
1. live VPS logs showed repeated invalid-user/root attempts and active fail2ban bans.

References:
1. MITRE ATT&CK T1110 (Brute Force): https://attack.mitre.org/techniques/T1110/
2. MITRE ATT&CK T1078 (Valid Accounts): https://attack.mitre.org/techniques/T1078/

Primary controls:
1. key-only SSH, no root login, no password auth
2. fail2ban + firewall rate limiting
3. MFA where interactive admin surfaces exist

### 2) Exploitation of unpatched internet-facing software
Why common:
1. CISA KEV explicitly tracks vulnerabilities exploited in the wild.
2. Attackers prioritize edge devices, web services, and management interfaces with known CVEs.

References:
1. CISA KEV catalog: https://www.cisa.gov/known-exploited-vulnerabilities-catalog
2. CISA #StopRansomware Guide: https://www.cisa.gov/stopransomware/ransomware-guide
3. MITRE ATT&CK T1190 (Exploit Public-Facing Application): https://attack.mitre.org/techniques/T1190/

Primary controls:
1. KEV-prioritized patching cadence
2. minimize exposed services/ports
3. emergency patch window for internet-facing CVEs

### 3) Security misconfiguration and weak defaults
Why common:
1. OWASP continues to rank misconfiguration and outdated components as top risks.
2. Small-server stacks often inherit permissive defaults (auth methods, verbose exposure, admin endpoints).

References:
1. OWASP Top 10:2021: https://owasp.org/Top10/2021/
2. OWASP A05 Security Misconfiguration: https://owasp.org/Top10/2021/A05_2021-Security_Misconfiguration/

Primary controls:
1. explicit baseline configs (SSH, firewall, logging)
2. remove/disable unused services
3. config drift checks

### 4) Ransomware/data-extortion precursor activity
Why common:
1. Ransomware operators often enter through exposed vulnerabilities or compromised credentials.
2. CISA guidance emphasizes prevention grouped by initial access vectors.

References:
1. CISA #StopRansomware Guide: https://www.cisa.gov/stopransomware/ransomware-guide
2. CISA StopRansomware portal: https://www.cisa.gov/stopransomware

Primary controls:
1. immutable/offline backups + restore testing
2. segmentation and least privilege
3. rapid incident reporting and containment path

## Practical risk ranking for small self-hosted servers
1. P0: exposed remote admin auth weakness (SSH/password, admin panels)
2. P0: unpatched KEV vulnerability on internet-facing service
3. P1: misconfigured reverse proxy / auth / headers / access control
4. P1: missing detection/response (no logs/alerting/ban automation)
5. P2: poor recovery posture (untested backups)

## Minimal defensive baseline (operator checklist)
1. SSH: keys only, root login off, auth retry limits, allowlist admin users.
2. Firewall: default deny inbound, only required ports exposed.
3. Patch: unattended security updates + KEV review workflow.
4. Detection: fail2ban + centralized logs + auth anomaly alerts.
5. Recovery: tested backup restore cadence.
6. Surface control: remove unused services/ports and management UIs from public internet.

## Related local docs
1. [0009-main-vps-hardening-audit-2026-03-05.md](/Users/virgil/Dev/rita-v4/docs/research/0009-main-vps-hardening-audit-2026-03-05.md)
