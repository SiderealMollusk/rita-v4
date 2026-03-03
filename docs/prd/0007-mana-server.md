# 0007 - Mana Server

## Definition

A `Mana Server` is the standardized compute contribution appliance:

- `LiteLLM + vLLM + collective glue`

## Role

Mana Servers provide:

- model serving capacity
- routable inference endpoints
- contributor-supplied compute for the collective

## Budgets And Visibility

The Mana Server should absorb most of the heavyweight operational burden around:

- compute accounting
- budget reporting
- model exposure
- capacity visibility
- request routing observability

This keeps the contributor surface simpler and pushes most compute-level mechanics into the standardized appliance.

## Non-Goal

A Mana Server is not generic personal infrastructure.

It is specifically a collective-aware compute contribution component.
