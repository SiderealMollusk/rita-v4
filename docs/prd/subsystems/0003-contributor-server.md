# 0003 - Contributor Server

## Purpose

The `Contributor Server` is the backstage backend for contributors.

It exists between the Hive and the contributor-facing page.

## Responsibilities

The contributor server owns:
- contributor-scoped configuration
- compute resource registration
- pilot license registration
- team and character management support
- backstage usage and budget visibility

## Role In The System

The contributor server is not the shared office.

It is the controlled backend that translates contributor intent into structured
platform configuration the Hive can respect.

## Non-Goals

The contributor server is not:
- the public product surface
- the social collaboration workspace
- the main execution engine
- the model-serving appliance

## Main Boundaries

The contributor server speaks to:
- the Hive
- the contributor page
- contributor-owned or contributor-managed resources

It should hide backstage complexity from the shared office.
