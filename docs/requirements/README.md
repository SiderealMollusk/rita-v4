# Requirements

## What You Will Find Here

Lightweight requirement and architecture reference docs.

These are intentionally short and orienting.
They are not implementation specs.

Start here:

1. [`platform/`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/)
2. [`product/`](/Users/virgil/Dev/rita-v4/docs/requirements/product/)

## Platform

1. [`0001-canonical-sources-of-truth.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0001-canonical-sources-of-truth.md)
2. [`0002-topology-and-lanes.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0002-topology-and-lanes.md)
3. [`0003-cluster-and-shared-services.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0003-cluster-and-shared-services.md)
4. [`0004-exposure-and-edge-model.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0004-exposure-and-edge-model.md)
5. [`0005-runbooks-and-operator-boundaries.md`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/0005-runbooks-and-operator-boundaries.md)

## Product

1. [`0001-product-thesis-and-shape.md`](/Users/virgil/Dev/rita-v4/docs/requirements/product/0001-product-thesis-and-shape.md)
2. [`0002-front-office-and-machine-core.md`](/Users/virgil/Dev/rita-v4/docs/requirements/product/0002-front-office-and-machine-core.md)
3. [`0003-core-entities.md`](/Users/virgil/Dev/rita-v4/docs/requirements/product/0003-core-entities.md)
4. [`0004-management-and-memory-model.md`](/Users/virgil/Dev/rita-v4/docs/requirements/product/0004-management-and-memory-model.md)
5. [`0005-tentpoles-and-constraints.md`](/Users/virgil/Dev/rita-v4/docs/requirements/product/0005-tentpoles-and-constraints.md)

Use these to recover the current architectural and product shape quickly before drilling into:

- `docs/progress_log/`
- `docs/plans/`
- `docs/prd/`
- machine-readable sources in `ops/`

## What You Will Not Find Here

Do not use this directory for:
1. detailed implementation plans
2. exploratory product design notes
3. validated operational change history
4. low-level machine-readable truth

Those belong in:
1. `docs/plans/`
2. `docs/prd/`
3. `docs/progress_log/`
4. `ops/` and `scripts/`

## When And How To Add To This Directory

Add here when:
1. a platform or product boundary has stabilized enough to be canonical
2. future sessions need a fast orientation layer
3. another directory keeps depending on an unstated assumption

When adding:
1. prefer numbered files or numbered subdirectories
2. keep notes short and orienting
3. avoid duplicating deep design discussion unless it has become a stable requirement

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/system-map.md`
2. the relevant child README in `platform/` or `product/`
3. `docs/plans/` if a requirement should also drive current execution
4. `docs/progress_log/` if the requirement came from newly validated live behavior
