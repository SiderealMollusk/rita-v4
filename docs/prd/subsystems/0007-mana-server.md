# 0007 - Mana Server

## Purpose

A `Mana Server` is the standardized compute contribution appliance.

It packages model-serving capacity in a collective-aware way.

## Shape

The current intended shape is:
- `LiteLLM`
- `vLLM`
- collective glue

## Responsibilities

A mana server should absorb most of the heavyweight compute mechanics around:
- model exposure
- routing visibility
- request accounting
- budget reporting
- capacity visibility

## Product Role

Mana servers let contributors supply horsepower without each contributor needing
to invent a private compute integration story.

## Non-Goals

A mana server is not:
- generic personal infrastructure
- the Hive
- the shared office
- the contributor page

## Main Boundaries

A mana server speaks to:
- the Hive
- contributor-controlled compute or hosting
- pilot execution through a standardized model-serving contract
