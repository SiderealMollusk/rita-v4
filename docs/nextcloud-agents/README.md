# Nextcloud Agents

## What You Will Find Here

This directory holds numbered design notes for the Nextcloud-facing agent model.

Use it for:
1. agent behavior inside Nextcloud
2. memory and artifact boundaries between workspace and machine systems
3. role and identity language for agents, souls, castes, and related concepts
4. human-visible collaboration patterns and control surfaces

Current entry point:
1. `0001-agents-as-clerical-coworkers.md`

## What You Will Not Find Here

Do not use this directory for:
1. low-level platform topology or cluster placement
2. concrete implementation plans for specific services
3. validated operational state or deployment progress
4. full product requirements or DDD specs

Those belong in:
1. `docs/requirements/`
2. `docs/plans/`
3. `docs/progress_log/`
4. `docs/prd/`

## When And How To Add To This Directory

Add a new numbered note when:
1. a stable conceptual boundary or interaction pattern emerges
2. a new agent/workspace behavior needs lightweight design capture
3. a new noun or coordination model needs to be anchored before implementation

When adding:
1. create the next numbered file
2. keep the note concept-first and light
3. prefer one idea per file
4. update this README entry list if the new file is a new entry point or major concept

## If You Add Here, What Else Should You Check

To avoid drift, check whether the change also requires updates to:
1. `docs/requirements/product/` if the concept has become a product tentpole
2. `docs/prd/` if the concept needs fuller product or domain elaboration
3. `docs/system-map.md` if this directory’s role or entry point changed
4. `docs/progress_log/` if the note reflects a newly validated live behavior rather than pure design
