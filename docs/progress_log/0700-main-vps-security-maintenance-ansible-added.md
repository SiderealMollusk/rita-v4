# 0700 - Main VPS Security Maintenance Ansible Added

Date: 2026-03-05
Status: Completed

## Summary
Added a canonical Ansible + host-wrapper security maintenance path for `main-vps` with persistent remote maintenance log/status files.

Added:
1. [43-security-maintenance-vps.yml](/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/43-security-maintenance-vps.yml)
2. [32-run-main-vps-security-maintenance.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/32-run-main-vps-security-maintenance.sh)
3. [vps.yml updates](/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/vps.yml)
4. [host runbook README updates](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/README.md)
5. [main-vps-security-maintenance.md](/Users/virgil/Dev/rita-v4/docs/platform/main-vps-security-maintenance.md)

## Logfile requirement implemented
Playbook writes:
1. `/var/log/security-maintenance.log`
2. `/var/lib/rita/security-maintenance.status`
3. `/var/lib/rita/security-maintenance-last-check.txt`

The status file initializes with `last_success_utc=never` and only flips to a timestamp after a successful completion.

## Validation
1. Local syntax checks passed:
- `ansible-playbook --syntax-check .../43-security-maintenance-vps.yml`
- `bash -n .../32-run-main-vps-security-maintenance.sh`

2. Initial live execution attempts were blocked by:
- temporary SSH reachability issues after snapshot/restore
- SSH agent signing failure (`communication with agent failed`)

3. Successful execution completed using direct key path:
- `ANSIBLE_PRIVATE_KEY_FILE=~/.ssh/id_ed25519 scripts/2-ops/host/32-run-main-vps-security-maintenance.sh`

4. Verified maintenance artifacts on `main-vps`:
- `/var/lib/rita/security-maintenance.status`
  - `last_success_utc=2026-03-05T19:42:17Z`
  - `last_run_result=success`
- `/var/lib/rita/security-maintenance-last-check.txt`
  - `fail2ban_active=True`
  - `ufw_active=True`
  - `docker_tcp_socket_exposed=False`
- `/var/log/security-maintenance.log` includes:
  - `START security-maintenance ...`
  - `SUCCESS security-maintenance ...`

## Next step
1. Run this maintenance script on a schedule (weekly or after major infra changes).
2. Add a lightweight alert if `last_success_utc` exceeds maintenance SLA.
