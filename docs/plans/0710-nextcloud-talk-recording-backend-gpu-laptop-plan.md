# 0710 - Nextcloud Talk Recording Backend On GPU Laptop

Date: 2026-03-06
Status: Proposed

## Goal

Stand up a dedicated Nextcloud Talk recording backend on the GPU laptop at `192.168.6.19` with minimal physical host changes, while making machine onboarding and runtime integration first-class repo state.

## Scope

In scope:
1. onboard new physical machine identity into repo automation
2. install and run Talk recording backend runtime on GPU laptop
3. integrate recording backend with existing Nextcloud/Talk deployment
4. keep HPB/signaling path unchanged
5. leave a repeatable install/verify runbook lane in `scripts/2-ops/workload/`

Out of scope (phase-later):
1. replacing HPB (`talk-hpb-vm` stays in place)
2. moving Nextcloud core services to GPU laptop
3. public exposure of recording service
4. complex diarization/live chunk streaming pipeline

## Current Baseline (from research)

1. Nextcloud: `cloud.virgil.info` on `nextcloud-vm` (`192.168.6.183`)
2. Talk HPB/signaling: `talk-hpb-vm` (`192.168.6.184`) via `https://cloud.virgil.info/standalone-signaling`
3. Recording backend: not configured (`recording_servers` unset)
4. New machine candidate: GPU laptop `192.168.6.19`

Reference docs:
1. [0016-nextcloud-talk-transcription-paths-2026-03-05.md](/Users/virgil/Dev/rita-v4/docs/research/0016-nextcloud-talk-transcription-paths-2026-03-05.md)
2. [0004-local-talk-transcription-and-gpu-host-setup.md](/Users/virgil/Dev/rita-v4/docs/research/0004-local-talk-transcription-and-gpu-host-setup.md)
3. [adding-a-machine.md](/Users/virgil/Dev/rita-v4/docs/platform/adding-a-machine.md)

## Design Constraints (Minimal Physical Changes)

1. Single-purpose host role: recording backend + optional local post-processing only.
2. Keep host OS simple (`Debian 12` or `Ubuntu Server 24.04 LTS`), no Proxmox, no k3s join.
3. No public DNS route for recording service; treat it as a private Pangolin resource and keep recording data-plane ingress restricted to LAN policy.
4. No host-level changes outside packages/services needed for recording runtime.
5. Manage config via repo + runbooks; avoid ad-hoc host edits.

## Canonical Machine Identity

Use this alias in automation:
1. inventory alias: `talk-recording-gpu`
2. management IP: `192.168.6.19`
3. ansible user: `virgil`
4. role class: physical host (workload-side service appliance)

## Required Repo Additions

### A) Inventory and host identity

1. add `ops/ansible/inventory/talk-recording.ini`
2. add `ops/ansible/host_vars/talk-recording-gpu.yml` for machine-specific facts
3. add [gpu-recording-node.md](/Users/virgil/Dev/rita-v4/docs/nodes/gpu-recording-node.md) documenting role, ownership, and dependencies
4. update [lab-nodes.md](/Users/virgil/Dev/rita-v4/docs/platform/lab-nodes.md) index entry

### B) Runtime source-of-truth

1. add `ops/nextcloud/talk-recording-runtime.yaml` with:
1. recording backend URL (`http://192.168.6.19:<port>`)
2. recording shared secret 1Password ref
3. optional local storage path, retention policy knobs
2. add/update `ops/nextcloud/instances.yaml` only if additional instance mapping is needed

### C) Runbook lane

Add scripts following existing naming pattern:
1. `scripts/2-ops/workload/47-install-nextcloud-talk-recording-runtime.sh`
2. `scripts/2-ops/workload/48-configure-nextcloud-talk-recording-runtime.sh`
3. `scripts/2-ops/workload/49-verify-nextcloud-talk-recording-runtime.sh`

Expected responsibilities:
1. install script: host package/runtime install + systemd service wiring
2. configure script: register recording backend in Nextcloud and set required shared secret
3. verify script: service health + signed callback/store path sanity + end-to-end recording smoke test

### D) Pangolin/Newt integration (private resource model)

1. add machine to `ops/pangolin/sites/required-sites.yaml` with `connector_mode: vm` (same control-plane posture as dedicated VM nodes)
2. onboard Newt site identity/credentials through the existing host lane
3. define recording endpoint as a private Pangolin resource (operator-visible, not public internet exposed)
4. keep Nextcloud-to-recording traffic on LAN address/policy

## Execution Plan

### Phase 1 - Onboard machine as first-class infra state

1. add inventory + host vars + node doc before touching runtime
2. register Newt site wiring for this host (bare-metal treated like VM in control-plane model)
3. verify inventory reachability (`ansible -i ... talk-recording-gpu -m ping`)
4. capture baseline progress note after identity is codified

Exit criteria:
1. machine identity exists in repo and is reachable by canonical alias
2. Newt site exists and is repo-tracked
3. no manual-only identity facts remain

### Phase 2 - Bootstrap minimal host runtime

1. install required base packages only (recording backend deps + ffmpeg/browser stack)
2. create dedicated service account and persistent directories
3. apply host firewall policy:
1. allow SSH from operator subnet
2. allow recording API port from `nextcloud-vm` (`192.168.6.183`) only
4. enable service with `Restart=always`
5. expose recording service as a private Pangolin resource only (no public route)

Exit criteria:
1. recording backend service active on GPU laptop
2. backend endpoint reachable from `nextcloud-vm`, blocked from unauthorized LAN peers
3. Pangolin resource is private and non-public

### Phase 3 - Integrate with Nextcloud Talk

1. add `recording_servers` config in Talk using runtime SoT values
2. set shared secret from 1Password ref (no secrets in git)
3. keep existing signaling config untouched (`cloud.virgil.info/standalone-signaling`)
4. validate admin warning for recording backend is cleared

Exit criteria:
1. Nextcloud reports recording backend configured
2. no regression in existing Talk signaling/HPB health

### Phase 4 - End-to-end validation

1. create test room, start/stop recording as moderator
2. confirm backend lifecycle events (`started`, `stopped`) are received
3. confirm final upload via `/recording/{token}/store` succeeds
4. confirm artifact appears in Nextcloud and backend temp files are cleaned

Exit criteria:
1. one full successful recording cycle without manual intervention
2. repeat run succeeds on second room/token

### Phase 5 - Optional GPU post-processing (after stable recording)

1. add post-finalize hook for transcript generation (`faster-whisper` local worker)
2. write transcript to deterministic Nextcloud path (`Transcripts/<call-id>.md`)
3. keep this lane decoupled from core recording start/stop/store flow

Exit criteria:
1. recording remains reliable even if STT worker is disabled
2. transcript path is deterministic and retry-safe

## Verification Contract

Minimum checks to declare done:
1. `47-install-*` and `49-verify-*` run cleanly from repo root
2. Nextcloud Talk can start and stop recording from UI without config errors
3. backend host journals show clean start/stop/store sequence
4. no new warnings/regressions in Talk signaling health checks

## Security And Operations Policy

1. recording backend is a private Pangolin resource; never exposed as a public internet route
2. recording data-plane ingress is LAN-restricted to the Nextcloud host policy
3. secrets resolved via 1Password refs at runtime
4. enforce retention policy for raw media on GPU laptop
5. include daily log and disk budget checks for backend storage
6. keep snapshot/rollback checkpoints before disruptive changes to Nextcloud/Talk VMs

## Rollback Plan

1. remove recording backend entry from Talk settings (or disable via script)
2. stop/disable recording runtime service on GPU laptop
3. keep HPB/signaling runtime unchanged
4. revert only affected runtime files/scripts if rollback is needed

## Suggested Deliverable Sequence

1. PR 1: machine onboarding files (inventory/host_vars/node doc)
2. PR 2: recording runtime SoT + install/configure/verify scripts
3. PR 3: integration + validation evidence + progress log
4. PR 4: optional STT post-processing lane

## Success Definition

1. GPU laptop is a documented, automatable node in repo state.
2. Talk recording backend is production-usable without ad-hoc host edits.
3. Existing Nextcloud/Talk services remain stable.
4. Path to optional GPU transcription is enabled but not required for core recording reliability.
