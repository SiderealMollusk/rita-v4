# 0600 - Transition From Platform To Product Dev

## Status

Active

## Purpose

This plan marks the transition from platform building into product planning and early application development.

It is the handoff document another agent should use before starting implementation work.

## Current Baseline

The validated platform baseline is:

1. the internal k3s cluster is live and stable enough to build on
2. `observatory`, `platform`, and `workload` are real lanes with intended roles
3. Flux is active
4. External Secrets is active
5. `platform-postgres` is live
6. Nextcloud is live at `app.virgil.info`
7. the current Nextcloud suite includes:
   - Collectives
   - Contacts
   - Calendar
   - Deck
   - Notes
   - Tasks
   - Talk

## Canonical Product Direction

The current canonical product direction is:

1. Nextcloud is the front office
2. Hive is the machine core
3. contributors interact with visible work through Nextcloud
4. agents should behave like diligent office workers
5. the system is Effect-first
6. `n8n` is deferred
7. `Mana Server` is a future standardized compute contribution appliance, not the first build target

Canonical product anchors live in:

1. `/Users/virgil/Dev/rita-v4/docs/requirements/product/`
2. `/Users/virgil/Dev/rita-v4/docs/prd/domain/`
3. `/Users/virgil/Dev/rita-v4/docs/prd/subsystems/`

## Canonical Versus Exploratory

Use these rules:

1. `docs/requirements/product/` is the active lightweight product truth
2. `docs/prd/` is exploratory elaboration and should not be treated as an execution-ready spec
3. `docs/progress_log/` is validated live state
4. this plan is the implementation handoff anchor

Another agent should not treat older product notes as equally authoritative if they conflict with this plan or with `docs/requirements/product/`.

## First Build Target

The first real development target is:

1. a Nextcloud shell
2. a Hive-lite machine core
3. one end-to-end paperwork agent loop

In plain terms:

1. read task state from Nextcloud
2. decide what to do next
3. perform one unit of work
4. write the paperwork back into Nextcloud

This is the first thing that proves the product, not a full contributor portal or a complete soul system.

## First Implementation Sequence

### Phase 1 - Nextcloud Shell

Build a small, explicit Nextcloud integration layer.

Scope:

1. authentication
2. read/write Deck state
3. read/write Collectives or Notes
4. post Talk messages
5. create/update Tasks if needed

Success condition:

1. one local program can read workspace state and write it back cleanly

### Phase 2 - Hive Lite

Build the smallest useful Hive domain.

Scope:

1. task claiming
2. leases or simple ownership
3. state transition recording
4. run ledger
5. one clear policy for "ready", "planning", "doing", "review", "done"

Success condition:

1. the machine core can safely decide and record one unit of work

### Phase 3 - One Paperwork Loop

Build one demonstrable agent loop.

Suggested shape:

1. pick a Deck card
2. decide whether it is ready
3. if not ready, move it to planning and create or update a supporting doc
4. if ready, do a bounded piece of work
5. post the result back into Nextcloud

Success condition:

1. a human can watch the system behave like a clerk in the shared office

### Phase 4 - Minimal Operator Surface

Start with a CLI, not a full UI.

Scope:

1. run the loop locally
2. inspect current state
3. manually trigger a unit of work
4. inspect a run record

Success condition:

1. development does not depend on a new web app before the domain is real

### Phase 5 - Mana Server Later

Only after the above is real:

1. standardize model-serving compute contribution
2. add contributor-managed compute registration
3. add richer routing, budgets, and policy

## Explicit Deferrals

Not now:

1. `n8n`
2. IdP work
3. Leantime
4. multi-instance Nextcloud
5. full contributor portal
6. full soul system
7. deep vector pipeline beyond minimal support
8. broad compute marketplace behavior

These may become important later, but they are not the next build step.

## Repo Shift

The repo should now shift from docs-heavy platform growth toward code-bearing product work.

Near-term code homes:

1. `apps/hive/`
2. `packages/nextcloud-shell/`

These do not need full implementation immediately, but they should become the center of gravity for the next phase.

## How To Use This Plan

Before starting implementation:

1. read `docs/requirements/product/`
2. read `docs/prd/domain/`
3. read `docs/prd/subsystems/`
4. then follow this plan, in order

If a future agent wants to add major new architecture before starting the first build target, that should be treated as drift unless it resolves a real blocker.
