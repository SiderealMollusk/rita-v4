# 0008 - Agent Memory And Execution Boundaries

## Collaborative Memory

Nextcloud is the primary collaborative memory substrate.

It is well-suited for:

- human-readable plans
- briefs
- knowledge pages
- visible task context
- social traces of work

## Execution Memory

The Hive owns execution memory:

- retries
- leases
- run state
- event ordering
- idempotency
- partial failure recovery

## Optional Vector / Index Layer

An optional vector or indexing layer may exist beside Nextcloud.

In v1, this should be treated as minimal and elementary.

Some amount of compute should explicitly go toward `hive maintenance`:

- deciding what should be indexed
- deciding what deserves embeddings
- pruning or refreshing retrieval material

This can become arbitrarily complex later, but it should start simple.

## Principle

Nextcloud should carry as much intelligence-facing memory as practical.

The sidecar memory systems should exist only where Nextcloud is weak.
