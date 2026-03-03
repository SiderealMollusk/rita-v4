# Product Subsystems

## What You Will Find Here

This directory holds lightweight subsystem stubs for the software collective.

Start here when you need to reason about the major moving parts without jumping
straight to implementation detail.

Current subsystem set:
1. `0001-nextcloud-front-office.md`
2. `0002-hive.md`
3. `0003-contributor-server.md`
4. `0004-contributor-page.md`
5. `0005-nextcloud-shell.md`
6. `0006-pilot-runtime.md`
7. `0007-mana-server.md`

Use it for:
1. subsystem purpose and boundaries
2. clear naming for future implementation plans
3. scoping what each subsystem should and should not own
4. preserving architectural tentpoles while leaving implementation room

## What You Will Not Find Here

Do not use this directory for:
1. canonical product requirements
2. validated operational state
3. detailed implementation plans
4. low-level API schemas or storage models

Those belong in:
1. `docs/requirements/product/`
2. `docs/progress_log/`
3. `docs/plans/`

## When And How To Add To This Directory

Add a new numbered subsystem note when:
1. a product subsystem has become a stable architectural noun
2. another document keeps hand-waving a boundary that should be named
3. future implementation work needs a stable anchor before planning starts

When adding:
1. create the next numbered file
2. keep the document short
3. focus on purpose, responsibilities, boundaries, and non-goals
4. prefer stable language over speculative implementation detail

It is expected that a subsystem may later be promoted from a single numbered
stub into its own directory with additional docs inside once the design space
is rich enough to justify it.

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/prd/README.md`
2. `docs/requirements/product/` if the subsystem has become a canonical tentpole
3. `docs/system-map.md`
4. `docs/progress_log/` if the new subsystem reflects a real product direction change
