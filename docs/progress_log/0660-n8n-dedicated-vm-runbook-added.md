# 0660 - n8n Dedicated VM Runbook Added

Date: 2026-03-05
Status: INCOMPLETE
Author: background agent
Freshness stamp: 2026-03-05

## Summary
Added durable documentation for onboarding a dedicated `n8n` VM using the existing workload VM pattern.

This captures the intended repo-native procedure so the next implementation pass can be done without ad hoc host work.

## Changes
1. Added freshness stamp and dedicated `n8n` VM section to:
- [adding-a-machine.md](/Users/virgil/Dev/rita-v4/docs/platform/adding-a-machine.md)
2. Added dedicated `n8n` VM bring-up runbook:
- [n8n-vm-bringup.md](/Users/virgil/Dev/rita-v4/docs/platform/n8n-vm-bringup.md)

## Why Incomplete
The runbook and machine procedure are documented, but implementation scripts/playbooks for the dedicated `n8n` VM lane are not yet created in this change.

Pending implementation includes:
1. `29-rebuild-n8n-vm.sh`
2. bootstrap/install/verify playbooks and wrappers for `n8n-vm`
3. optional Pangolin VM connector record and wire-up for `n8n-vm`

## Next Step
Implement the documented wrappers/playbooks, then run rebuild -> bootstrap -> install -> verify and log runtime evidence.
