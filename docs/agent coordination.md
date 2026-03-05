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

### Agent: codex
- Status: incomplete
- Started: 2026-03-04 09:00 PST
- Scope: Bring up `n8n` on the main worker via the platform GitOps lane
- Files: `ops/gitops/platform/apps/n8n/`, `ops/gitops/clusters/internal/kustomization.yaml`, `ops/gitops/platform/observability/targets.tsv`, `ops/gitops/platform/backup-state/services.tsv`, `scripts/2-ops/host/22-bootstrap-n8n-db.sh`
- Blockers: `ops-brain` / cluster API unreachable from the Mac host; `192.168.6.16:6443` and SSH both returned host-down during live validation
- Notes: Repo scaffolding is in place, ExternalSecret now matches the single `n8n-secrets` 1Password item, and local render/syntax checks passed. Live reconcile and DB bootstrap did not complete.
- Next step: Resume cluster-side bring-up once `ops-brain` is reachable again

## Recent Handoffs

Move finished or paused entries here with their final state and next action.
