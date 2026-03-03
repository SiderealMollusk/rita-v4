# 0520 - Doc Directory Governance READMEs Added

Validated: 2026-03-03
Status: Active

## Summary

Added or expanded `README.md` files for the numbered documentation directories so each area now states:

1. what belongs there
2. what does not belong there
3. when and how to add new docs
4. what adjacent directories or indexes to check to avoid drift

This is lightweight governance rather than a product or platform behavior change, but it is intentional and should be treated as part of the repo's documentation maintenance contract.

## Directories Covered

1. [`docs/requirements/`](/Users/virgil/Dev/rita-v4/docs/requirements/)
2. [`docs/requirements/platform/`](/Users/virgil/Dev/rita-v4/docs/requirements/platform/)
3. [`docs/requirements/product/`](/Users/virgil/Dev/rita-v4/docs/requirements/product/)
4. [`docs/prd/`](/Users/virgil/Dev/rita-v4/docs/prd/)
5. [`docs/plans/`](/Users/virgil/Dev/rita-v4/docs/plans/)
6. [`docs/pangolin/`](/Users/virgil/Dev/rita-v4/docs/pangolin/)
7. [`docs/nextcloud-agents/`](/Users/virgil/Dev/rita-v4/docs/nextcloud-agents/)

## Why It Matters

The repo now has several numbered doc trees with different purposes:

1. requirements
2. product design
3. plans
4. validated progress
5. subsystem reference notes

Without explicit directory-level rules, new notes are easy to place inconsistently and cross-directory drift becomes more likely.

## Current Rule

Before adding a new numbered doc to one of these directories:

1. read that directory's `README.md`
2. follow its scope and contribution guidance
3. check the listed adjacent directories or indexes for required updates

## Follow-On

When a new numbered doc tree is introduced later, it should get a `README.md` with the same governance shape immediately rather than after drift appears.
