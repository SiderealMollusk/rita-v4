# 0001 - Agents As Clerical Coworkers
Status: ACTIVE
Date: 2026-03-03

## Core Idea

Agents should not only compute in the backend and dump outputs into storage.

They should:
1. move tickets
2. write and update docs
3. leave notes
4. negotiate responsibilities in chat
5. publish summaries and follow-ups
6. behave like diligent paperwork-loving employees inside the shared workspace

The desired effect is not perfect human imitation.
It is legible, collaborative workplace behavior.

## Architectural Position

This is a hybrid model:

1. `Nextcloud` is the visible office
2. the agent backend is the operational control plane

The two layers are both real.

### Nextcloud is for:
1. shared visible work
2. long-lived knowledge
3. human review and intervention
4. agent-created artifacts that should feel like normal workplace outputs

### The backend is for:
1. scheduler state
2. agent run state
3. retries and failure handling
4. structured event logs
5. traces and observability
6. memory indexing and retrieval internals
7. policy and permissions

## The Key Design Principle

Every important agent action should have:
1. a workspace action in Nextcloud
2. an operational record outside Nextcloud

Examples:
1. an agent writes a Collective page and the backend stores the run, prompts, tools, and linked artifacts
2. an agent moves a Deck card and the backend stores the causal event and scheduling state
3. an agent posts in Talk and the backend stores the run context and completion signal

This keeps the workspace legible without making Nextcloud the only source of truth for machine operations.

## Canonical Truth Split

### Canonical outside Nextcloud
1. `ticket`
2. `run`
3. `event`
4. `artifact`
5. `agent`
6. `tool invocation`
7. `trace`
8. `memory embedding/index metadata`

### Canonical inside Nextcloud
1. curated project knowledge
2. collaborative docs
3. human-facing boards
4. visible task surfaces
5. notes and summaries that are meant to be read and maintained

### Mirrored into Nextcloud
1. ticket summaries
2. agent reports
3. deck state for human visibility
4. curated KB pages
5. follow-up tasks

### Mirrored out of Nextcloud
1. changed Collective content for indexing
2. task/card changes for scheduling reconciliation
3. explicit human approvals and edits
4. selected Talk events used as collaboration signals

## Nextcloud Role Mapping

### Collectives
Use for:
1. project briefs
2. runbooks
3. agent-written reports
4. curated knowledge base content
5. decision records

This is the strongest place for agent-readable and human-readable shared memory.

### Deck
Use for:
1. human-visible ticket boards
2. project and queue summaries
3. lightweight planning surfaces

Deck should feel primary to humans even if queue truth is maintained in the backend.

### Tasks
Use for:
1. individual follow-ups
2. small explicit action items
3. reminders that do not need full board structure

### Notes
Use for:
1. scratch outputs
2. temporary summaries
3. personal or lightweight shared notes

### Talk
Use for:
1. role negotiation
2. handoffs
3. completion signals
4. visible agent chatter
5. alerts meant to be seen as workplace communication

Talk should not be the only message bus.
It should be a collaboration surface that is backed by the operational event system.

## Desired User Experience

Humans should experience agents as coworkers who:
1. open and update work items
2. write briefs and reports
3. post coordination messages
4. maintain the knowledge base
5. leave the office more organized than they found it

The backend should quietly guarantee that:
1. actions are traceable
2. retries are safe
3. schedules are real
4. failures are inspectable
5. memory retrieval is efficient

## Suggested V1 Shape

### Backend owns
1. scheduler
2. priority and triage engine
3. agent harness
4. event log
5. traces
6. memory indexing
7. canonical ticket state

### Nextcloud exposes
1. Collectives for project knowledge
2. Deck for human-facing board state
3. Tasks for action items
4. Talk for visible negotiation and handoffs

### Bridge responsibilities
1. project backend state into Deck and Tasks
2. index Collective pages into agent memory
3. publish agent reports into Collectives
4. treat Talk messages as collaboration events, not sole truth

## Anti-Patterns

Do not:
1. make Talk the only transport or event bus
2. make Deck the only queue state
3. make Collectives the only machine memory
4. rely on Nextcloud alone for auditability or retry behavior

## Why This Model Fits

This model preserves both goals:
1. agents behave in a legible, office-like way inside Nextcloud
2. the platform still has engineering-grade rigor underneath

That means the office theater is useful, not fake.

## Follow-On Questions

1. What should the canonical backend ticket model look like?
2. Which Nextcloud events should be ingested into memory and which should remain presentation-only?
3. How should Talk rooms map to roles, queues, or projects?
4. Which artifacts should be published automatically versus manually promoted into Collectives?
