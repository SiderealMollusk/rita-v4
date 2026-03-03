# Product Requirement 0004

## Purpose

This document captures the current management and memory model.

## Management Model

The current UX model is:

- humans act like C-levels
- soulful agents act like D-level managers
- thin agents act like workers and clerks

Humans should mostly:

- set direction
- review boards and dashboards
- talk to higher-level characters
- drop down to raw tasks mostly for debugging or deep intervention

## Collaborative Memory

`Nextcloud` is the primary collaborative memory substrate.

It is good for:

- knowledge
- briefs
- board state
- visible context
- social traces of work

## Execution Memory

The `Hive` owns the machine-only memory:

- retries
- exact event ordering
- leases
- idempotency
- run metadata

An optional vector and index layer may exist, but it is deliberately elementary at first.

Some amount of compute should be reserved for basic `Hive maintenance`:

- analyzing what should be indexed
- deciding what should be vectorized
- keeping retrieval useful

This can become arbitrarily complex later, but should remain elementary in v1.

