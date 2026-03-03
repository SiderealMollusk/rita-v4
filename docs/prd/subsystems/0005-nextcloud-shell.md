# 0005 - Nextcloud Shell

## Purpose

The `Nextcloud Shell` is the collective-aware interface layer for talking to the
Nextcloud workspace.

It is the structured way machine systems perform office work.

## Responsibilities

The shell should make it easy to:
- read and write work surfaces in Nextcloud
- publish paperwork and outcomes
- consume task state and collaborative memory
- expose stable operations over app-specific Nextcloud APIs

## UX Intent

The shell is how agents and pilots behave like diligent office workers without
needing direct human-style browser interaction.

## Non-Goals

The shell is not:
- the scheduler
- the lease authority
- the source of execution truth
- the personality layer

## Main Boundaries

The shell sits between:
- the Hive or pilot runtime
- the Nextcloud front office

It should translate machine actions into office-visible behavior.
