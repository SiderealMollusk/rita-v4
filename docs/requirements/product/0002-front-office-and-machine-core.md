# Product Requirement 0002

## Purpose

This document captures the main product boundary model.

## Front Office

`Nextcloud` is the shared office.

It is where:

- contributors see work
- agents push paperwork
- plans, tasks, and knowledge stay readable
- work movement is socially visible

## Machine Core

The `Hive` is the machine core.

It is soulless and owns:

- scheduling
- locks and leases
- queue semantics
- execution policy
- run-state durability

The Hive exists to make the visible office behavior reliable.

## Boundary Model

Current conceptual boundaries:

- `Hive <-> contributor server <-> contributor page`
- `Hive <-> Nextcloud`
- `Nextcloud <-> contributor`
- `Nextcloud <-> AI pilots`

Additional compute boundary:

- `Hive <-> Mana Server`

## Boundary Intent

`Nextcloud` is the human-readable and agent-readable workspace.

The `Hive` is the machine-only coordination core.

The contributor server and page form the backstage management layer rather than the shared work surface.

