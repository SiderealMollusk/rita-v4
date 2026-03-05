# 0610 - Pangolin API Management Migration
Status: ACTIVE
Date: 2026-03-04

## Goal
Replace host-side Pangolin CLI and UI-driven workflows with API-driven, repo-managed automation while preserving the current operator safety boundaries.

This plan focuses on Pangolin resource/site management.
It does not replace Pangolin server deployment on VPS in this phase.

## Why Now
Current repo behavior is partly declarative (blueprint YAML) but applied through host-side ad hoc steps:
1. human site creation in Pangolin UI
2. manual snippet paste into 1Password
3. CLI-based `pangolin apply blueprint` mutations

That gives weak drift detection and weak idempotency guarantees compared to direct API contracts.

## Current State (Repo Inventory)
Current Pangolin mutation flow is concentrated in:
1. `scripts/2-ops/host/20-apply-observatory-monitoring-blueprint.sh`
2. `scripts/2-ops/host/21-apply-nextcloud-blueprint.sh`
3. `scripts/2-ops/host/23-apply-nextcloud-cloud-blueprint.sh`
4. `scripts/2-ops/host/10-write-observatory-pangolin-site-secret.sh`
5. `scripts/2-ops/host/24-register-pangolin-site-credentials.sh`
6. `scripts/2-ops/host/25-register-pangolin-sites.sh`
7. `scripts/lib/pangolin-site-credentials.sh`
8. `ops/pangolin/blueprints/observatory/*.blueprint.yaml`
9. `docs/pangolin/0002-human-site-registration.md`

## API Surface To Use
From Pangolin Integration API v1:
1. API key lifecycle: `/org/{orgId}/api-key`, `/org/{orgId}/api-keys`, `/org/{orgId}/api-key/{apiKeyId}/actions`
2. Site lifecycle: `/org/{orgId}/site`, `/org/{orgId}/sites`, `/site/{siteId}`
3. Public resources: `/org/{orgId}/resource`, `/org/{orgId}/resources`, `/resource/{resourceId}`
4. Resource targets: `/resource/{resourceId}/target`, `/resource/{resourceId}/targets`
5. Blueprint apply/list: `/org/{orgId}/blueprint`, `/org/{orgId}/blueprints`
6. Audit/verification: `/org/{orgId}/logs/action`, `/org/{orgId}/logs/request`, `/org/{orgId}/logs/access`

## Target Architecture
### 1. API-first host tool
Create one canonical host script (or small script set) that:
1. reads desired state from `ops/pangolin/blueprints/`
2. resolves org/site IDs via API
3. applies blueprint or resource mutations via API
4. verifies post-state via list/get endpoints
5. fails closed on unknown or ambiguous matches

### 2. Secret model
1. store Pangolin API key in 1Password as a dedicated item
2. keep Newt site `id`/`secret` separate from API key material
3. stop requiring pasted Helm snippets for ongoing resource changes

### 3. Drift model
1. preflight fetch live resources/sites
2. compare against desired blueprint spec
3. apply only required creates/updates/deletes
4. emit machine-readable change summary

## Migration Phases
### Phase 0 - Contract Lock
1. confirm org scoping and auth model for API key actions in live Pangolin
2. define required action scope for least-privilege key
3. add API contract note under `docs/pangolin/` with endpoint list used by repo

Exit criteria:
1. one documented API auth contract
2. one validated API key with minimum required permissions

### Phase 1 - Read-only API Probe
1. add script: `scripts/2-ops/host/26-pangolin-api-readonly-check.sh`
2. validate token, org lookup, site list, resource list, blueprint list
3. print canonical IDs for `observatory` site and key resources

Exit criteria:
1. reproducible read-only output from API
2. no dependence on Pangolin CLI for read paths

### Phase 2 - Blueprint Apply by API (Shadow Mode)
1. add script: `scripts/2-ops/host/27-apply-pangolin-blueprint-api.sh`
2. continue running existing CLI apply in parallel for one cycle
3. compare API post-state vs CLI post-state
4. keep writes limited to one blueprint (`observatory-monitoring`) first

Exit criteria:
1. API apply converges to same effective state as CLI path
2. dry-run and apply output stable across repeated runs

### Phase 3 - Cutover Resource Workflows
1. migrate these scripts to API-backed implementation:
   - `20-apply-observatory-monitoring-blueprint.sh`
   - `21-apply-nextcloud-blueprint.sh`
   - `23-apply-nextcloud-cloud-blueprint.sh`
2. keep script names for operator continuity; swap internals from CLI to API
3. deprecate direct `pangolin apply blueprint` in runbook docs

Exit criteria:
1. resource exposure updates are API-only
2. no operator step requires Pangolin CLI auth session for normal applies

### Phase 4 - Site Registration Improvement
1. replace manual site metadata entry with API lookups where possible
2. reduce `10/24/25` flows to Newt credential ingest + validation only
3. keep human gate only for sensitive one-time values that API cannot return safely

Exit criteria:
1. no manual copy of site identifier/name for existing sites
2. human input minimized to true secret bootstrap boundaries

### Phase 5 - Observability + Policy
1. add API-backed verify script:
   - `scripts/2-ops/host/28-verify-pangolin-api-state.sh`
2. record action/request log slices after applies
3. emit concise report suitable for `docs/progress_log/`

Exit criteria:
1. each apply has a corresponding API verification artifact
2. drift and auth failures are diagnosable without UI inspection

## Mapping: Current Ad Hoc -> API Path
1. `pangolin apply blueprint --file ...`
   -> `PUT /org/{orgId}/blueprint` + `GET /org/{orgId}/blueprints`
2. UI checks for resource presence
   -> `GET /org/{orgId}/resources` + `GET /resource/{resourceId}/targets`
3. manual site lookup
   -> `GET /org/{orgId}/sites` / `GET /org/{orgId}/site/{niceId}`
4. ad hoc post-change verification
   -> `GET /org/{orgId}/logs/action` and `GET /org/{orgId}/logs/request`

## Risks
1. API action scoping may be narrower than expected; apply could fail until correct permissions are assigned
2. blueprint schema in API may differ subtly from CLI expectations
3. one-time site bootstrap values (Newt credentials) may still require protected manual handling

## Guardrails
1. keep existing CLI scripts runnable during shadow phase until API parity is proven
2. no destructive delete path in first API write scripts unless explicit `--allow-delete` flag is set
3. always resolve and verify `orgId` before mutation
4. never write API keys to repo files or shell history

## Deliverables
1. API auth contract doc in `docs/pangolin/`
2. read-only API health script (`26-*`)
3. API blueprint apply script with dry-run (`27-*`)
4. API state verify/report script (`28-*`)
5. updated host runbook docs removing CLI-first wording

## Immediate Next Actions
1. implement `26-pangolin-api-readonly-check.sh`
2. create dedicated 1Password item for Pangolin API key and wire read path
3. implement `27-apply-pangolin-blueprint-api.sh` for monitoring blueprint only
4. run one shadow apply cycle and compare with current CLI behavior
