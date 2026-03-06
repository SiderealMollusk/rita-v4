# Akasha Brainstorming (Round 1)

## Project intent
Akasha is a local development/monitoring server that runs on my dev machine and reflects my home lab the way I think about it, not the way a generic monitoring tool models it.

Core UX direction:
- Node boxes with status lights
- Terminal feeds showing live status evaluations/commands
- Hover tooltips that explain exactly how each indicator is controlled

Proposed stack direction:
- React + Flow for UI/domain typing
- Effect.js for executing and orchestrating checks/commands

## Scope nouns (initial)
Monitor what currently has a Source of Truth (SoT) in this repo, including:
- Physical machines
- Virtual machines
- Containers
- Services
- Pangolin topology
- LAN topology
- DNS status
- Secrets
- SoT integrity/status itself

Note: this is enough nouns for first pass.

## Status-light meaning (initial)
Primary goal: a node should be solid green only when all of these are true:
- Working
- Documented
- Reachable
- "As it should be" for that node type

Interpretation:
- Green is a composite state, not just a single health check (for example, not just `healthz == 200`).
- Other colors/states are TBD and should be defined after first check framework is in place.

## Terminal feed concept
Terminal feeds are not just logs; they are the visibility layer for evaluations.

Intent:
- Use Effect.js to run actual terminal commands/check scripts
- Stream command execution + results into the web UI
- Reduce need for custom one-off reporting
- Reduce routine need to dig through Grafana for basic situational awareness

## Tooltip principle
Tooltips must answer: "Why is this light this color right now?"

Example:
- `pangolin [green]` should expand to criteria details (not just `healthz 200`), potentially including:
- Health endpoint state
- Dependent site reachability
- Round-trip or trace-based checks (for example via OTEL)
- Last successful/failed evaluation timestamps

## Mature-state vision
In a mature version of Akasha:
- You can see as much of your home lab as you have mapped/defined in SoT
- Coverage expands naturally as your system mapping grows
- Akasha becomes the operational "truth window" for current state vs intended state

## Working design ideas (first pass)
- Every node has:
- Identity (name/type/owner)
- Declared intent (what "as it should be" means)
- Check set (commands + logic)
- Status reducer (how individual checks roll up)
- Explanation payload (tooltip details)

- Status is computed in layers:
- Reachability layer
- Functional layer
- Documentation/SoT alignment layer
- Topology consistency layer

- UI slices:
- Topology graph pane (node boxes + lights)
- Terminal feed pane (live command/effect stream)
- Detail drawer/panel (criteria, evidence, last transitions)

## Open questions for Round 2
1. What is the first minimal vertical slice node type? (service, VM, or DNS)
2. What is the first concrete non-green state definition? (yellow vs red semantics)
3. Where should check definitions live in-repo? (single registry file vs per-domain folders)
4. What update cadence is acceptable per check type? (seconds/minutes/manual)
5. What should be considered a "documentation pass" signal initially?

## Near-term milestone sketch
1. Define one node schema and one status reducer in code.
2. Implement one Effect.js check runner that executes shell commands safely.
3. Stream runner output to a terminal panel in React.
4. Compute a first composite green state for 1-2 nodes.
5. Render tooltip evidence for why the current state was assigned.

## Market-neighbor reality check (closest matches)
Closest existing categories:
1. Internal developer portals with scorecards (`Backstage`, `Port`, `OpsLevel`, `Cortex`).
2. Infra source-of-truth tools (`NetBox`, `Nautobot`).
3. Traditional monitoring/status-map tools (`Checkmk`, `Netdata`).

Why Akasha still has room:
1. local-first and homelab-first
2. explicit SoT-integrity in status color semantics
3. terminal-evidence-native UX (not only dashboards)

## Fast FOSS "nail-gun" stacks

### Stack A (recommended first): Custom thin app + proven OSS data plane
1. `React + React Flow` UI for node graph + detail drawers.
2. `Effect.js` check runner service for command execution and status reducers.
3. `OpenTelemetry Collector` for normalized telemetry/event ingest.
4. `Prometheus` + `Loki` for metrics/log history.
5. `NetBox` as optional SoT for topology/IPAM truth.

Why:
1. minimal lock-in
2. all components are open source
3. you keep your custom status semantics in code

### Stack B (faster visuals): Netdata/Uptime-Kuma for baseline + custom overlay
1. Use `Uptime Kuma` or `Netdata` for quick health baseline.
2. Build Akasha UI as opinionated overlay that computes your composite green logic from SoT + checks.

Why:
1. fast time-to-value
2. defer deep observability plumbing while UI model is still moving

### Stack C (catalog-first): Backstage + custom plugin + local check runner
1. Use `Backstage` as entity/catalog shell.
2. Add Akasha plugin for status lights, terminal feed, and explanation payload.

Why:
1. avoids building catalog/auth/plugin framework from zero
2. still allows custom logic surface

## Suggested first implementation cut (2 weekends)
1. Build only 3 node types: `service`, `vm`, `dns`.
2. Implement one check registry file and one reducer.
3. Save check evidence snapshots to JSONL on disk.
4. Render topology + terminal stream + tooltip explanation.
5. Add one SoT drift signal (`documented` + `reachable` + `expected route`).
