# Agent Coordination

This file is the shared coordination point for parallel agents working in this repo.

Use it to reduce overlap, surface blockers early, and leave a short handoff when you stop.

## How To Use This File

Before starting substantial work:
1. add a new entry under `Active Work`
2. claim the area you are touching
3. list the main files or directories you expect to edit

While working:
1. keep your entry current if scope changes
2. note blockers as soon as they appear
3. mark if cluster access, secrets, or another agent are required

When stopping or handing off:
1. move the entry to `Recent Handoffs`
2. mark it `complete`, `incomplete`, or `blocked`
3. leave the next concrete step

## Entry Template

Copy this block:

```md
### Agent: <name or short id>
- Status: active | blocked | complete | incomplete
- Started: YYYY-MM-DD HH:MM TZ
- Scope: <what you are working on>
- Files: <paths you expect to touch>
- Blockers: <none or short blocker list>
- Notes: <short progress note>
- Next step: <single next action>
```

## Active Work

None currently.

## Recent Handoffs

Move finished or paused entries here with their final state and next action.

### Agent: background agent
- Status: incomplete
- Started: 2026-03-05 11:50 PST
- Scope: Document dedicated `n8n` VM onboarding procedure and link it from machine onboarding guidance
- Files: `docs/platform/adding-a-machine.md`, `docs/platform/n8n-vm-bringup.md`, `docs/progress_log/0660-n8n-dedicated-vm-runbook-added.md`
- Blockers: none
- Notes: Added freshness stamps, created a dedicated `n8n` VM bring-up runbook, and logged an incomplete progress note signed `background agent`.
- Next step: Implement the referenced `n8n-vm` rebuild/bootstrap/install/verify wrappers and playbooks.

### Agent: codex
- Status: incomplete
- Started: 2026-03-05 09:05 PST
- Scope: Execute plan 0690 (`n8n` VM nuke-and-pave), then codify full VM-site + Pangolin-resource automation chain
- Files: `ops/gitops/platform/apps/n8n/*`, `ops/pangolin/sites/required-sites.yaml`, `ops/pangolin/blueprints/observatory/n8n.blueprint.yaml`, `scripts/2-ops/host/31-apply-n8n-blueprint.sh`, `scripts/2-ops/workload/39-bring-up-n8n-vm-k8s-pangolin.sh`, `docs/platform/n8n-vm-bringup.md`
- Blockers: none during runtime execution; pending multi-agent git packaging
- Notes: Added canonical `n8n_vm` required-site record, added n8n Pangolin blueprint + host apply wrapper, and added a no-arg end-to-end chain script that includes site reconcile, VM Newt wiring, and n8n resource apply.
- Next step: run host-side Pangolin apply/verify on live infra and confirm `https://n8n.virgil.info` is healthy.
