# 0490 - Platform ARD Refactored Into Numbered SoTs

Validated: 2026-03-03

## Summary

The lightweight platform ARD was refactored from a single broad sketch into a numbered set of short platform architecture reference docs. The new set is explicitly organized around canonical sources of truth and current validated platform boundaries.

## What Changed

Added:

- `docs/requirements/platform/0001-canonical-sources-of-truth.md`
- `docs/requirements/platform/0002-topology-and-lanes.md`
- `docs/requirements/platform/0003-cluster-and-shared-services.md`
- `docs/requirements/platform/0004-exposure-and-edge-model.md`
- `docs/requirements/platform/0005-runbooks-and-operator-boundaries.md`

Updated:

- `docs/requirements/README.md`
- `docs/system-map.md`

Removed:

- `docs/requirements/platform/`

## Intent

The point of the refactor is to make the platform ARD area easier to scan and more clearly anchored to repo truth:

- inventory
- group vars
- host vars
- routes
- internal cluster GitOps root
- current validated progress notes

## Current Reading Shape

Use the platform ARDs as fast orientation docs, then drop to the machine-readable sources when you need proof or implementation detail.
