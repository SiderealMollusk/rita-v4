# 0530 - Product Domain Spec Seeded

## Summary

Added the first explicit product domain-spec layer under `docs/prd/domain/`.

This seeds three high-level notes:
1. glossary
2. bounded contexts and context map
3. contracts and expectations

The intent is to stabilize product language and boundary assumptions before implementation planning gets deeper.

## Added

- `docs/prd/domain/README.md`
- `docs/prd/domain/0001-glossary.md`
- `docs/prd/domain/0002-bounded-contexts-and-context-map.md`
- `docs/prd/domain/0003-contracts-and-expectations.md`

## Updated

- `docs/prd/README.md`
- `docs/system-map.md`

## Notes

This is intentionally not a final model.

It is a breathable domain layer meant to:
1. keep future agents aligned on the core nouns
2. keep subsystem and implementation planning anchored to shared boundaries
3. reduce drift between the evolving product metaphor and the eventual machine design
