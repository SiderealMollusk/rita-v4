# Freshness

This doc explains how to decide whether a repo document should be trusted as current.

The repo contains:
1. plans
2. progress notes
3. summary docs
4. reference docs
5. automation code

They do not all age the same way.

## Core Rule
When documents disagree, prefer the most implementation-close and most recently validated source.

In practice, that usually means:
1. active automation and committed manifests
2. the latest relevant progress note
3. the current active plan
4. summary/reference docs
5. older historical notes

## Document Types
### 1. Automation Code
Examples:
1. `ops/ansible/`
2. `ops/gitops/`
3. `ops/helm/`
4. `scripts/`
5. `manifests/`

Interpretation:
1. this is the strongest evidence for what the repo can currently do
2. code can still be wrong or incomplete, but it is closer to reality than prose summaries

Use when:
1. you need exact inputs, outputs, file locations, inventory names, or execution steps
2. a summary doc sounds stale or vague

### 2. Progress Notes
Location:
1. `docs/progress_log/`

Interpretation:
1. these are timestamped statements about what was learned, changed, or validated
2. the latest relevant note is often the best freshness anchor for a topic

Use when:
1. you need to know what was most recently proven
2. a node doc or summary doc says “start with the latest relevant progress note”

Rule:
1. newer is not automatically better unless it is relevant to the same topic

### 3. Plans
Location:
1. `docs/plans/`

Interpretation:
1. plans describe intended architecture or intended execution
2. active plans are normative for direction, not proof of completed implementation

Use when:
1. deciding what the repo is trying to do next
2. checking the intended boundary or sequence for work in progress

Rule:
1. a plan may supersede an older plan in direction
2. a plan does not by itself prove the work is done

### 4. Summary Docs
Examples:
1. `docs/topology.md`
2. `docs/system-map.md`
3. `docs/lab-nodes.md`
4. `docs/service-placement.md`
5. `docs/nodes/*.md`

Interpretation:
1. these are navigation and orientation aids
2. they are useful, but they are not the strongest source when implementation details matter

Use when:
1. you need the shape of the system quickly
2. you want to know where to look next

Rule:
1. summary docs should point to fresher sources
2. if they stop doing that, they should be corrected

### 5. Reference Docs
Examples:
1. `docs/pangolin/0001-deploy-model.md`
2. `docs/vocabulary.md`
3. `docs/access-policy.md`
4. `docs/freshness.md`

Interpretation:
1. these define stable rules, terminology, or conceptual boundaries
2. they should change less often than implementation plans

Use when:
1. you need repo conventions
2. you need interpretation rules, not runtime state

## Freshness Signals
### `Validated: YYYY-MM-DD`
Meaning:
1. this document claims it was checked against reality on that date

Interpretation:
1. good signal for reference/summary docs
2. not proof that every linked automation path still works today

### `Status: ACTIVE`
Meaning:
1. this plan or workstream is still current

Interpretation:
1. use it as current intended direction
2. do not treat it as proof of completion

### `Status: COMPLETE` or `DONE`
Meaning:
1. the note claims the described work reached a concluded state

Interpretation:
1. useful historical checkpoint
2. may still be superseded by newer work later

### `## Freshness`
Meaning:
1. the document explicitly tells you what newer source to consult first

Interpretation:
1. follow it
2. this is the repo’s preferred way to prevent summary-doc drift

### `Freshness anchor`
Meaning:
1. a progress note is acting as the current checkpoint for a topic

Interpretation:
1. treat that note as the first historical checkpoint to read for that topic

## Conflict Resolution
If sources disagree, resolve in this order:
1. current automation/manifests
2. latest relevant progress note
3. active plan with the most specific scope
4. summary/reference docs
5. older plans and older progress notes

## Practical Reading Order
### For “what exists right now?”
1. automation/manifests
2. latest relevant progress note
3. node/service summary docs

### For “what are we trying to build next?”
1. active plan
2. linked progress note
3. supporting summary docs

### For “what words should we use?”
1. `docs/vocabulary.md`

### For “which summary should I trust?”
1. one that includes explicit freshness guidance
2. one that links to current progress notes
3. one that matches current automation paths

## Expected Author Behavior
When editing docs:
1. add or update `## Freshness` in summary docs when drift is likely
2. update navigation docs when the current active plan changes
3. do not silently let an old summary remain the main entry point to a superseded design
4. use progress notes to lock decisions and validations with dates
5. keep historical notes historical rather than rewriting them to look current

## Short Version
1. code/manifests beat prose
2. latest relevant progress note beats older summaries
3. active plans beat stale plans
4. summary docs should help you navigate, not pretend to be the only source of truth
