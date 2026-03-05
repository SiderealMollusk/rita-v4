# 0011 - Targeted Known-Domain Attacker Model And Hardening Plan
Date: 2026-03-05
Status: Rewritten operator report

## Context
Threat model requested:
1. low routine clear-net activity
2. attacker already knows your domain
3. therefore risk is targeted reconnaissance and precision intrusion, not only broad internet spray-and-pray

## What changes in this threat model

### 1) "Obscurity" value drops
If attacker already has domain knowledge, they can still enumerate and profile exposed assets.

Key mechanisms:
1. internet-wide active scanning of exposed services
2. passive certificate visibility through CT logs

References:
1. Censys internet scanning model: https://docs.censys.com/docs/internet-scanning
2. Let's Encrypt CT logs (public certificate logging): https://letsencrypt.org/docs/ct-logs/

Operational meaning:
1. fewer users does not equal lower targeted risk
2. every exposed endpoint must be intentionally justified and hardened

### 2) Likely attack sequence for your profile
1. Recon: enumerate certs/subdomains/services/ports
2. Initial access:
- brute-force/credential stuffing against SSH/admin surfaces
- exploit public-facing application vulnerability (especially known exploited CVEs)
3. Persistence/expansion:
- use valid credentials or weak service trust boundaries
- deploy malware/backdoors or abuse container/service runtime
4. Impact:
- data theft, extortion leverage, service disruption

References:
1. MITRE T1110 Brute Force: https://attack.mitre.org/techniques/T1110/
2. MITRE T1190 Exploit Public-Facing Application: https://attack.mitre.org/techniques/T1190/
3. MITRE T1078 Valid Accounts: https://attack.mitre.org/techniques/T1078/
4. CISA KEV catalog: https://www.cisa.gov/known-exploited-vulnerabilities-catalog

## Rewritten hardening report for this model

### Priority 0 (do now)
1. Keep SSH key-only and root-login-disabled (already applied on VPS).
2. Keep fail2ban healthy and monitored (already fixed and active).
3. Enforce KEV-priority patching for all internet-facing components.
4. Keep public ingress minimal: only required ports/services.

### Priority 1 (next hardening wave)
1. Add host telemetry and tamper evidence:
- `auditd`
- file integrity monitoring (AIDE)
2. Container/runtime hardening:
- lock down Docker daemon config
- document which containers require public port publishing and why
- verify no unexpected privileged/container escape-risk settings
3. Detection/response:
- alert on successful SSH login events
- alert on repeated auth failures from new ASNs/IP ranges

### Priority 2 (resilience)
1. backup/restore drills for critical configs and app state
2. short incident runbook for "known-domain targeted attack" event:
- isolate ingress
- rotate credentials/keys
- inspect persistence points
- recover from known-good state

## Controls specifically matched to your current VPS findings
1. Continuous SSH attack noise is already present: keep ban/rate-limit controls and add alerting.
2. Public ports 80/443 + UDP endpoints are intentional for current stack; keep strict inventory of exposed services and remove anything non-essential.
3. Certs are publicly visible by design (CT): treat subdomain and certificate footprint as discoverable intelligence.

## References
1. CISA KEV: https://www.cisa.gov/known-exploited-vulnerabilities-catalog
2. CISA #StopRansomware Guide: https://www.cisa.gov/stopransomware/ransomware-guide
3. CISA Secure by Design: https://www.cisa.gov/securebydesign
4. Verizon 2025 DBIR hub: https://www.verizon.com/business/resources/reports/dbir/
5. OWASP Top 10 (2021): https://owasp.org/Top10/2021/
6. MITRE T1110: https://attack.mitre.org/techniques/T1110/
7. MITRE T1190: https://attack.mitre.org/techniques/T1190/
8. MITRE T1078: https://attack.mitre.org/techniques/T1078/
9. Let's Encrypt CT logs: https://letsencrypt.org/docs/ct-logs/
10. Censys scanning model: https://docs.censys.com/docs/internet-scanning
11. NIST SP 800-123: https://www.nist.gov/publications/guide-general-server-security
12. NIST SP 800-63B-4: https://www.nist.gov/publications/nist-sp-800-63b-4digital-identity-guidelines-authentication-and-authenticator
