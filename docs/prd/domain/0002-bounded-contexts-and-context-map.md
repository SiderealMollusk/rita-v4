# 0002 - Bounded Contexts And Context Map

This note sketches the likely bounded contexts without claiming the final code layout.

## Purpose

The goal is to separate:
1. the social and collaborative surfaces
2. the machine-operational core
3. the contribution and compute economy
4. the actor and identity model

## Proposed Bounded Contexts

### Workspace Context

The Workspace context covers the front office.

It includes:
1. Nextcloud-visible work surfaces
2. collaboration artifacts
3. boards, notes, docs, tasks, and chatter
4. the signals humans and pilots can observe directly

### Hive Context

The Hive context covers the machine core.

It includes:
1. scheduling
2. leases and locks
3. run tracking
4. queue state
5. policy-driven work routing
6. machine-level orchestration

### Identity And Labor Context

This context covers:
1. contributors
2. teams
3. souls
4. castes
5. characters
6. agent instances

It is responsible for the language of who is doing work and in what role.

### Contribution Context

This context covers:
1. compute resources
2. mana servers
3. pilot licenses
4. budgets
5. usage visibility

It is responsible for what resources are available to the collective and under what terms.

### Backstage Context

This context covers:
1. contributor server
2. contributor page
3. backstage management workflows

It is responsible for contributor-facing control, not daily collaborative work.

### Pilot Execution Context

This context covers:
1. pilot invocation
2. shell behavior
3. model/tool interaction
4. context assembly
5. writeback effects

It is the place where a pilot actually performs work on behalf of a character or caste.

## Context Relationships

### Workspace <-> Hive

The Workspace emits visible work state and human directives.

The Hive consumes those signals and projects machine decisions back into the Workspace.

### Hive <-> Pilot Execution

The Hive decides what work should be attempted.

Pilot Execution performs the work and returns outcomes.

### Hive <-> Contribution

The Hive consumes compute and pilot availability through the Contribution context.

The Contribution context constrains where and how work can run.

### Backstage <-> Contribution

Backstage provides the human control plane for contribution objects such as compute resources, budgets, and pilot licenses.

### Backstage <-> Identity And Labor

Backstage is also where contributors are expected to manage teams, castes, souls, and characters outside the front office.

### Pilot Execution <-> Workspace

Pilot Execution reads and writes the front office through explicit shell/adapters.

It should not collapse the Workspace into the same context as the Hive.

## Important Boundary Rule

Nextcloud is not the whole system.

The Workspace context is a major surface of the product, but not the same thing as:
1. the Hive
2. pilot execution
3. contribution management

## Open Questions

1. whether Identity And Labor should later split into separate `Identity` and `Labor` contexts
2. whether Contribution and Backstage should remain distinct if the contributor server becomes small
3. whether a future analytics or observability context should be modeled separately rather than folded into Hive
