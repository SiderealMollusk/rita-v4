# 0510 - Product Requirements Refactored Into Numbered Docs

Validated: 2026-03-02

## Summary

The product requirement sketch under `docs/requirements/product/` was split from a single catch-all note into the same numbered shape used by `docs/requirements/platform/`.

## Changes

- replaced the single product requirement sketch with numbered product requirement docs:
  - `0001-product-thesis-and-shape.md`
  - `0002-front-office-and-machine-core.md`
  - `0003-core-entities.md`
  - `0004-management-and-memory-model.md`
  - `0005-tentpoles-and-constraints.md`
- updated `docs/requirements/README.md`
- updated `docs/system-map.md`

## Why It Matters

The product side now mirrors the platform side:

- fast to scan
- easier to extend
- easier for later agents to orient on specific concepts without reading one large blended note

## Freshness Anchor

When recovering product intent quickly, start with:

- `docs/requirements/product/`
- then move into `docs/prd/` and `docs/nextcloud-agents/` as needed
