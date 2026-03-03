# Domain Spec

## What You Will Find Here

This directory holds the high-level domain vocabulary and boundary model for the software collective.

Start here:
1. `0001-glossary.md`
2. `0002-bounded-contexts-and-context-map.md`
3. `0003-contracts-and-expectations.md`

Use it for:
1. stabilizing the shared language of the product
2. sketching bounded contexts before implementation plans exist
3. defining contracts between the Hive, Nextcloud, contributor-facing systems, and pilots
4. giving future agents a constrained but breathable frame for detailed design

Subsystem stubs in `docs/prd/subsystems/` are expected to be promoted into richer directories as needed. This directory should do the same if the domain model grows beyond a few numbered notes.

## What You Will Not Find Here

Do not use this directory for:
1. low-level implementation plans
2. concrete API endpoint definitions
3. database schemas
4. validated operational truth
5. generic architecture notes that do not use the shared domain language

Those belong in:
1. `docs/plans/`
2. `docs/progress_log/`
3. implementation-local docs later, when subsystems become real code

## When And How To Add To This Directory

Add a new numbered domain note when:
1. a core noun needs stronger definition
2. a boundary between subsystems needs to be made explicit
3. a contract or invariant is important enough that future implementation work should respect it

When adding:
1. create the next numbered file
2. prefer language, boundaries, and invariants over implementation detail
3. mark uncertainty directly instead of forcing premature certainty
4. update this README if the reading order or purpose changes

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/requirements/product/` if a concept has become a stable tentpole
2. `docs/prd/subsystems/README.md` if the new note changes subsystem boundaries
3. `docs/system-map.md` if this directory should be called out more explicitly
4. `docs/progress_log/` if a domain note reflects a decision that has now become validated direction
