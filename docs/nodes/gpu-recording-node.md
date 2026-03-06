# Node: gpu-recording-node

## Identity
- Host alias: `talk-recording-gpu`
- Role: dedicated Nextcloud Talk recording backend host
- Hardware class: GPU laptop
- Management IP source of truth: `ops/ansible/inventory/talk-recording.ini`

## Access
- SSH user: `virgil`
- SSH port: `22`
- Expected admin model: `virgil` + sudo

## Runtime Intent
- Runs recording backend runtime for Nextcloud Talk.
- Can host optional local post-processing workers (for example, STT) after core recording is stable.
- Does not replace Nextcloud core VM or Talk HPB VM.

## Network Intent
- Control-plane access is managed via Newt/Pangolin site record:
  - `slug`: `talk_recording_gpu`
  - `connector_mode`: `vm`
  - `op_item_title`: `pangolin_site_talk_recording_gpu`
- Recording data-plane traffic remains private and LAN-restricted by host policy.

## Verify
1. `ops/ansible/inventory/talk-recording.ini`
2. `ops/ansible/host_vars/talk-recording-gpu.yml`
3. `ops/pangolin/sites/required-sites.yaml`
4. `docs/plans/0710-nextcloud-talk-recording-backend-gpu-laptop-plan.md`
