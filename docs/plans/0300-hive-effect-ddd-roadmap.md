# 0300 - Hive Architecture & Effect-DDD Roadmap

## Status: Draft
## Context
The "Hive" is the machine core of the Rita V4 homelab/software collective. It manages scheduling, task locking, and coordination between agents and the "Front Office" (Nextcloud). This roadmap defines the transition from the "notebook" of patterns in `modulith-dx` to a production-ready, EffectTS-powered implementation in `rita-v4`.

---

## Phase 1: Foundations & Lego Blocks (The Substrate)

### 1.1 Effect-DDD Primitives
We will consolidate the 13 primitives from `modulith-dx` into a more idiomatic `Effect` structure.
- **Domain Entities & Value Objects**: Powered by `Effect.Schema`. This provides runtime validation and type-safety in a single definition.
- **Use Cases**: Every UseCase will be an `Effect<A, E, R>` wrapped in a mandatory `Span`. This *forces* observability (auto-logging and tracing) at the type level.
- **Ports & Adapters**: Use `Effect.Context.Tag` for Port definitions and `Effect.Layer` for Adapter implementations. This allows seamless switching between `InMemory` (testing) and `Postgres` (prod).

### 1.2 The Caste Registry
- **Source of Truth**: A YAML-based configuration for agent "Castes" (e.g., Code Monkey, QA, Director).
- **Schema**: Defined via `Effect.Schema`, allowing the Hive to validate agent capabilities and permissions at boot.
- **Purpose**: Provides a stable API for higher-level agents (Directors) to delegate tasks to specialized "soulless" workers.

---

## Phase 2: The Nextcloud Organ (The Integration)

### 2.1 Nextcloud Adapter Strategy
The Hive needs to "duplicate UI affordances" for agents.
- **Auth**: Centralized Nextcloud credential management (likely via a System Agent or a per-caste pool).
- **Toolbox**: High-level Effect services for:
  - `DeckService`: CRUD cards for task tracking.
  - `TalkService`: Post updates and status reports to human-facing channels.
  - `TaskService`: Manage explicit checklists.
  - `CollectiveService`: Read/write briefs and knowledge.

### 2.2 Lightweight Interface Layer
- **CLI-First**: We will prioritize a robust CLI (and possibly a simple REST/Websocket bridge) over complex frameworks. This keeps the Hive "light" and easy for any agent (Python, TS, or even a raw LLM) to interact with via standard tool-calling patterns.

---

## Phase 3: The Job Lifecycle (The Machine Core)

### 3.1 Strict Interpretation
- **Idempotency**: Using the `modulith-dx` concept of `CommandId`, the Hive ensures no task is executed twice accidentally.
- **Leasing**: A locking mechanism to prevent multiple agents from "checking out" the same ticket.
- **Reconciliation**: A background effect that checks "Nextcloud Deck" against "Hive Internal State" to find drifted or abandoned tasks.

---

## Technical Design Principles (The "Taste")

1. **Extreme Type Safety**: If it compiles, the domain invariants should be mostly satisfied.
2. **Forced Observability**: You cannot write a "naked" business logic function. It must be wrapped in an Effect that logs its entry, exit, and failures.
3. **In-Memory Testing**: The entire Hive domain should be testable in CI/CD without a database, using `Effect.Layer.succeed` for all external ports.
4. **LLM-Friendly Patterns**: Primitives should be recognizable enough that an LLM can "guess" how to implement a new UseCase or Entity by looking at existing examples.

---

## Next Steps (Actionable)
1. Implement the `src/shared/kernel` types for `UseCase` and `Entity`.
2. Scaffold `src/hive/domain` and `src/hive/adapters/nextcloud`.
3. Create the `Caste` YAML schema and a sample `code-monkey.yaml`.
