# Ops Philosophy

This directory is for **authoritative automation**.

## Rules
- `ops/` contains source-of-truth infrastructure logic.
- Automation here may be parameterized and reusable.
- Inventories, vars, templates, and playbooks live here.

## Boundaries
- `ops/` is not optimized for interactive operator ergonomics.
- `scripts/` provides zero-argument, numbered runbook wrappers for day-to-day execution.

See: [scripts/README.md](/Users/virgil/Dev/rita-v4/scripts/README.md)

## Current Structure
- `ansible/`: inventories, vars, and playbooks for host/bootstrap/deploy operations.
