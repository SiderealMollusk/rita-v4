# 0001 - Glossary

This glossary is intentionally tentative. It exists to make future design work cohere, not to freeze every term permanently.

## Core Human And Organizational Terms

### Contributor

A trusted human participant in the software collective.

A contributor may:
1. direct work
2. manage teams
3. contribute compute
4. manage pilots
5. interact with the front office in Nextcloud
6. interact with backstage systems through the contributor page

### Team

A contributor-managed social and operational grouping.

A team may own:
1. groups in Nextcloud
2. souls
3. castes
4. characters
5. compute allocations
6. policies and budgets

## Core Worker Terms

### Soul

A durable continuity and personality service consulted by a pilot.

A soul is not the worker body itself. It carries continuity, tone, preferences, and higher-order memory across runs.

For now, a soul is expected to look more like a stable chat endpoint or continuity service than a free-floating markdown file.

### Caste

A reusable role template.

A caste defines:
1. skills
2. tools
3. permissions
4. operating doctrine
5. model class expectations
6. default work style

### Character

The recognizable worker identity formed by combining a soul and a caste.

Working shape:
1. `Character = Soul + Caste + Overrides`

Not every worker requires a soul. Some work may be performed by a caste without durable continuity.

### Pilot

The active intelligence currently driving a character or work session.

A pilot may be:
1. a chat loop
2. a custom harness
3. a local or remote model-driven process
4. a contributor-supplied reasoning process

The pilot is not the same thing as the soul.

### Shell

The interface layer through which a pilot acts on the collective.

In the current direction, the shell is expected to mediate interaction with Nextcloud and other collective surfaces.

### Agent Instance

A live running worker.

Working shapes:
1. `Agent Instance = Character + Compute`
2. `Agent Instance = Caste + Compute` for soulless execution

The agent instance is ephemeral compared with the soul and the caste.

## Core System Terms

### Hive

The soulless machine core.

The Hive is responsible for:
1. locks
2. schedulers
3. queues
4. leases
5. run state
6. work routing
7. machine-level policy

The Hive is not the same as the front office and is not itself a personality-bearing actor.

### Mana Server

A preconfigured compute contribution appliance.

Current intended shape:
1. `LiteLLM + vLLM + collective glue`

The mana server is where heavyweight compute-serving concerns should tend to live.

### Contributor Server

The backstage backend used to manage contribution-oriented concerns.

It is expected to deal with:
1. compute registration
2. pilot licenses
3. budgets
4. team configuration
5. visibility into contributed resources

### Contributor Page

The contributor-facing backstage UI layered over the contributor server.

It is not the same thing as Nextcloud, which remains the front office.

### Front Office

The human-facing collaborative surface of the collective.

In the current product direction, Nextcloud is the front office.

## Memory Terms

### Collaborative Memory

Human-readable and shareable memory that agents and humans both use.

Examples:
1. Collectives
2. Deck boards
3. Talk conversations
4. Notes
5. Tasks

### Execution Memory

Machine-oriented operational state required to make automation safe and reliable.

Examples:
1. retries
2. leases
3. in-flight work state
4. exact event ordering
5. run metadata
6. trace linkage

## Terms To Use Carefully

### Agent

Use carefully because it is overloaded.

Prefer one of:
1. `Character`
2. `Pilot`
3. `Agent Instance`
4. `Hive`

depending on what is actually meant.

### Personality

Avoid as a primary architectural term.

Prefer `Soul` when continuity and role identity are meant.

## Open Terms

The following terms are intentionally not settled yet:
1. whether a `Mandate` should exist as a stable concept between team and task
2. whether a `Workstream` should be a first-class object
3. whether `privacy grade` and `trust domain` remain one axis or split into two later
