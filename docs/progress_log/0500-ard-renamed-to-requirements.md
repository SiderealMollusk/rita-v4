# 0500 ARD Renamed To Requirements

Validated: 2026-03-03

## Summary

The lightweight architecture sketch area has been renamed from `docs/ard/` to `docs/requirements/`.

The new structure is:

- `docs/requirements/platform/`
- `docs/requirements/product/`

The platform side is now organized as numbered requirement sketches instead of a generic ARD label.

## Why

The old `ard` name was vague.

`requirements` is a better fit for these documents because they capture:

- canonical platform boundaries
- current lane intent
- current product tentpoles

without pretending to be full implementation specs.

## New Canonical Paths

- [`docs/requirements/README.md`](/Users/virgil/Dev/rita-v4/docs/requirements/README.md)
- [`docs/requirements/platform/0001-canonical-sources-of-truth.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0001-canonical-sources-of-truth.md)
- [`docs/requirements/platform/0002-topology-and-lanes.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0002-topology-and-lanes.md)
- [`docs/requirements/platform/0003-cluster-and-shared-services.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0003-cluster-and-shared-services.md)
- [`docs/requirements/platform/0004-exposure-and-edge-model.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0004-exposure-and-edge-model.md)
- [`docs/requirements/platform/0005-runbooks-and-operator-boundaries.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0005-runbooks-and-operator-boundaries.md)
- [`docs/requirements/product/`](/Users/virgil/Dev/rita-v4/docs/requirements/product/)
