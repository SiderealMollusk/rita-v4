# 0005 - Hive Machine Core

## Definition

The `Hive` is the soulless machine core.

It owns:

- schedulers
- locks and leases
- queue semantics
- exact event ordering
- retries
- idempotency
- run metadata
- execution policy
- caste registry

## Purpose

The Hive is not the visible office.

It is the machine guts that make the office behavior safe and durable.

## Boundaries

The Hive talks to:

- contributor servers
- Nextcloud
- mana servers

It should not be confused with:

- a Soul
- a pilot
- a human-facing workspace
