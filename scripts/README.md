# Scripts Philosophy

This directory is for **operator-facing runbooks as code**.

## Rules
- Scripts are **numbered** and **opinionated**.
- Scripts are **localized** to this repo/workflow.
- Scripts take **no arguments**.
- Scripts should read like an execution narrative ("documentation as code").

## Numbering
- `0-*`: one-time local/bootstrap setup
- `1-*`: per-session bring-up/checks
- `2-*`: operations workflows

## Boundaries
- `scripts/` is for curated execution flow and ergonomics.
- `ops/` is for authoritative, reusable automation logic (Ansible, templates, inventories).

See: [ops/README.md](/Users/virgil/Dev/rita-v4/ops/README.md)
