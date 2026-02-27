# 0100 - Pangolin Staging/Prod Replication Plan
Status: 🟡 IN PROGRESS
Date: 2026-02-26
Major Milestone: Build near-full staging/prod ops parity and deploy Pangolin with low risk.

## Goal
Create a two-environment setup:
- Staging: Oracle Cloud free-tier VPS.
- Production mirror: second local machine.

This provides full rehearsal of core ops workflows (bootstrap, k8s, ESO, deploy, rollback), excluding heavy workers.

## Strategy
- Use Oracle free-tier as internet-reachable staging for real domain/DNS/TLS behavior.
- Use the second machine as production-like infrastructure for repeated runbooks and safe validation.
- Keep configurations aligned across both environments using Ansible and shared manifests.

## Environment Model
1. Staging (Oracle VPS)
- Publicly reachable host.
- Domain + DNS configured for Pangolin staging endpoint.
- Single-node k3s + ESO + Pangolin.

2. Production mirror (second machine)
- Same k3s/ESO/Pangolin bootstrap pattern.
- Same secret model and manifests.
- Heavy workers excluded to fit resources.

## Phased Plan
1. Oracle account and host provisioning
- Sign up for Oracle Cloud free tier.
- Create one Linux VM for staging.
- Harden host (SSH keys, non-root sudo user, firewall, updates, swap).

2. Ansible foundation
- Create inventory for staging and mirror hosts.
- Build playbooks:
  - host bootstrap
  - k3s install
  - ESO + SecretStore + test ExternalSecret
  - Pangolin deploy/verify/rollback

3. Staging bring-up (Oracle)
- Install k3s and ESO.
- Apply `0010-onepassword-store.yaml` and `0020-test-secret.yaml`.
- Confirm secret sync returns `bar`.
- Deploy Pangolin and validate domain/TLS/health.

4. Production mirror bring-up (second machine)
- Run same Ansible path with mirror inventory.
- Verify same readiness and secret checks.
- Validate runbook parity (deploy + rollback) without heavy workers.

5. Promotion readiness
- Freeze known-good versions/configs.
- Finalize rollback procedure and smoke tests.
- Use staging outcomes to drive live production rollout decisions.

## Punch List
- [ ] Create Oracle free-tier account and provision staging VM.
- [ ] Record staging VM metadata in node docs (IP, region, role, OS, sizing).
- [ ] Prepare second machine as production mirror node and document it.
- [ ] Scaffold `ops/ansible` structure with shared roles/playbooks.
- [ ] Create inventories: one for staging VM, one for production mirror.
- [ ] Automate host hardening for both environments.
- [ ] Automate k3s install for both environments.
- [ ] Automate ESO install + SecretStore + ExternalSecret apply.
- [ ] Validate secret pipeline in staging (`bar` decode check).
- [ ] Validate secret pipeline in production mirror (`bar` decode check).
- [ ] Automate Pangolin deploy and rollback playbook steps.
- [ ] Validate staging domain/TLS/login flow end-to-end.
- [ ] Run the same deploy/verify/rollback procedure on mirror.
- [ ] Capture final runbook and promote to live production workflow.

## Testing Criteria (Pass/Fail)
1. Infrastructure parity
- Pass: staging and production mirror run the same Ansible playbooks with only inventory/vars differences.
- Fail: manual snowflake steps are required in either environment.

2. Secret pipeline
- Pass: `SecretStore` Ready=True and `lab-test-sync` Ready=True in both environments.
- Pass: decoded `rita-test-k8s-secret` value is `bar` in both environments.
- Fail: any readiness or decode check fails.

3. Pangolin deploy health
- Pass: Pangolin deploy succeeds without crash loops in both environments.
- Pass: staging endpoint responds successfully over domain/TLS.
- Fail: pod instability, repeated errors, or endpoint failure.

4. Operational runbook quality
- Pass: deploy, verify, and rollback all execute from documented commands/playbooks.
- Pass: rollback returns environment to known-good state.
- Fail: rollback is incomplete, untested, or ambiguous.

5. Production readiness
- Pass: staging + mirror both pass all checks and runbooks are repeatable.
- Pass: heavy-worker exclusions are documented and accepted.
- Fail: unresolved gaps in core ops workflow.

## Current Decision
Proceed with Oracle free-tier staging plus second-machine production mirror as the primary path to safe Pangolin rollout.
