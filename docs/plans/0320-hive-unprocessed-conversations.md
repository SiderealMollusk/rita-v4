# 0320 - Hive Unprocessed Conversations & Context

## Context
This document captures high-level goals, metaphors, and requirements from the initial planning sessions for the Hive. These items are not yet codified into the roadmap but represent the "north star" for the project.

---

## 1. The Hive Metaphor & Organs
- **The Collective**: Rita V4 is becoming a software collective.
- **Hive as Machine Guts**: Unlike Nextcloud (the human office), the Hive is the "soulless" machine core.
- **Recognizable Organs**:
  - **Nextcloud Organ**: Manages auth, accepting agent reports, and "duplicating UI affordances" (Deck, Talk, Tasks).
  - **Scheduler/Lock Organ**: Reconciles distributed state and ensures strict job interpretation (checking out tickets, retries, idempotency).
  - **Inference/Execution Organ**: Actually runs the agents, gets context, and fires off tool calls.

## 2. Agent Identities
- **Soul vs. Caste**:
  - **Soul**: Durable personality/continuity (chat endpoint).
  - **Caste**: Professional template (skills, tools, model choice).
  - **Character**: Soul + Caste + Overrides.
- **Soulless Execution**: Many agents (like the "Code Monkey") don't need personality; they just need to do a tight job in parallel.

## 3. Human-Agent Interaction
- **Nextcloud as Front Office**: Agents should act like coworkers—moving cards in Deck, writing briefs in Collectives, and "chatting" in Talk.
- **Communication Channels**: Agents talk to each other in Talk (for human-facing logs) but interact primarily through tickets and documents.
- **Humans & Pilots**: Shouldn't drop deeper than talking to Project Managers (PMs) in Talk.

## 4. Technical Desires
- **Durable Substrate**: The Hive should survive framework churn by focusing on protocols and "LEGO blocks."
- **YAML-Driven Workflows**: Training an "employee" (agent) should be as simple as defining a workflow in a stable YAML schema.
- **Tooling**: Prioritize "buttons agents can push" to perform paperwork.
- **Testing**: Heavy emphasis on In-Memory testing for CI/CD, while maintaining a clear path to production Postgres.

## 5. Open Questions & Future Directions
- **MCP vs. CLI**: Ongoing evaluation of the "Interface Layer." CLI is currently preferred for its lightweight nature, but MCP is being watched for tool interoperability.
- **Director Agents**: How much do we "break down" tasks? Training "director level" agents to handle flows and delegation is a major future milestone.
