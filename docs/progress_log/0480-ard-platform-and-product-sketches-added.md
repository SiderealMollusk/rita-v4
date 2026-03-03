# 0480 - ARD Platform And Product Sketches Added

Validated: 2026-03-02

## What Changed

Added a lightweight architecture reference area:

- `docs/requirements/README.md`
- `docs/requirements/platform/`
- `docs/requirements/product/`

These are intentionally short orientation docs rather than detailed implementation specs.

## Why

The repo now has enough real platform state and enough product direction that future work needs a fast way to recover:

- current platform reality
- current product tentpoles

without reading the full plan and progress history first.

## Platform Sketch Scope

The platform requirement sketches backfill the current platform shape from the repo and recent validated milestones:

- single internal cluster
- `ops-brain`, `platform`, `workload`
- Flux, ESO, `platform-postgres`, Nextcloud
- Pangolin exposure model

## Product Sketch Scope

`docs/requirements/product/` captures the current high-level product model:

- software collective
- Nextcloud as front office
- Hive as machine core
- contributor / soul / caste / character / mana server terminology
- trusted contributor model
- humans as C-level, soulful agents as D-level, thin agents as clerks

## Freshness

These docs are sketches, not proof.

For validated operational truth, continue to prefer:

- `docs/system-map.md`
- `docs/progress_log/0450-platform-postgres-live-with-image-workaround.md`
- `docs/progress_log/0470-nextcloud-live-and-bootstrapped.md`
