# Product Requirements

## What You Will Find Here

This directory holds the numbered, lightweight canonical product requirements.

Start here:
1. `0001-product-thesis-and-shape.md`
2. `0002-front-office-and-machine-core.md`
3. `0003-core-entities.md`
4. `0004-management-and-memory-model.md`
5. `0005-tentpoles-and-constraints.md`

Use it for:
1. stable product tentpoles
2. shared vocabulary anchors
3. the minimum product shape future agents should recover first
4. boundaries between product thesis and implementation

## What You Will Not Find Here

Do not use this directory for:
1. rich exploratory product sketches
2. detailed execution plans
3. live operational validation
4. low-level domain or API specifications

Those belong in:
1. `docs/prd/`
2. `docs/plans/`
3. `docs/progress_log/`

## When And How To Add To This Directory

Add a new numbered requirement when:
1. a product concept has stabilized enough to be treated as canonical
2. another doc keeps relying on an unstated product boundary
3. a new top-level product area needs a lightweight anchor

When adding:
1. create the next numbered file
2. keep it short and orienting
3. prefer stable language over implementation detail

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/requirements/README.md`
2. `docs/prd/` if the new requirement deserves deeper expansion
3. `docs/system-map.md`
4. `docs/progress_log/` if the requirement was derived from newly validated live behavior
