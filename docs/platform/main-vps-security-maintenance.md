# Main VPS Security Maintenance

Validated: 2026-03-05
Status: Active

## Purpose
Define the canonical Ansible path for recurring security maintenance on `main-vps`.

## Canonical entrypoint
Run from Mac host terminal:
1. [32-run-main-vps-security-maintenance.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/32-run-main-vps-security-maintenance.sh)

Playbook executed:
1. [43-security-maintenance-vps.yml](/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/43-security-maintenance-vps.yml)

## What the playbook enforces/checks
1. baseline security packages (`ufw`, `fail2ban`, `unattended-upgrades`, `auditd`, `aide`, etc.)
2. SSH hardening policy (`sshd_config.d/99-hardening.conf`)
3. fail2ban SSH jail policy (`backend=systemd`, ufw banaction)
4. UFW defaults + SSH rate limit + expected public service ports
5. baseline kernel networking `sysctl` hardening values
6. security check summaries for SSH/fail2ban/UFW/docker socket exposure

## Security maintenance logfile/state
Remote files created/updated by playbook:
1. `/var/log/security-maintenance.log`
- append-only run markers (`START` / `SUCCESS`)

2. `/var/lib/rita/security-maintenance.status`
- `last_success_utc=<timestamp>`
- `last_success_epoch=<epoch>`
- `last_run_result=success`
- initialized to `never` if no successful run has occurred yet

3. `/var/lib/rita/security-maintenance-last-check.txt`
- lightweight check snapshot (fail2ban/ufw/docker socket exposure)

## Variable contract
Security policy variables live in:
1. [vps.yml](/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/vps.yml)

Key controls:
1. `vps_ssh_allowed_users`
2. `vps_public_tcp_ports`
3. `vps_public_udp_ports`
4. `vps_fail2ban_*`

## Failure handling
If the run fails before completion:
1. no success marker is written to `security-maintenance.status`
2. last successful timestamp remains previous value (or `never`)
3. check SSH/UFW service state on host console before rerun
