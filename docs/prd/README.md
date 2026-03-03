# PRD

## What You Will Find Here

This directory holds numbered product design and expansion notes for the software collective.

Start here:
1. `0001-nextcloud-software-collective.md`
2. `0002-trust-and-governance-model.md`
3. `0003-roles-identities-and-workers.md`
4. `0004-nextcloud-as-front-office.md`
5. `0005-hive-machine-core.md`
6. `0006-contributor-backstage.md`
7. `0007-mana-server.md`
8. `0008-agent-memory-and-execution-boundaries.md`
9. `0009-work-lifecycle-and-prioritization.md`
10. `0010-roadmap-and-open-questions.md`

Use it for:
1. product elaboration beyond the lightweight requirements
2. design language and concept development
3. unresolved but serious product shaping work
4. richer sketches that help future implementation planning
5. subsystem stubs in `docs/prd/subsystems/`
6. domain vocabulary and boundary shaping in `docs/prd/domain/`

## What You Will Not Find Here

Do not use this directory for:
1. canonical lightweight product requirements
2. validated operational status
3. step-by-step execution plans
4. concrete implementation specs

Those belong in:
1. `docs/requirements/product/`
2. `docs/progress_log/`
3. `docs/plans/`

## When And How To Add To This Directory

Add a new numbered PRD note when:
1. the product concept needs deeper exploration than `docs/requirements/product/` should carry
2. a new major product concern emerges and needs room to breathe
3. you need to sketch implications and open questions without freezing implementation too early

When adding:
1. create the next numbered file
2. keep it concept-first
3. avoid turning it into an execution plan
4. update this README if the new file should be part of the default reading order

## If You Add Here, What Else Should You Check

To avoid drift, also check:
1. `docs/requirements/product/` if the new idea has become a stable tentpole
2. `docs/system-map.md` if the directory role or recommended entry point changed
3. `docs/progress_log/` if the PRD note reflects something that has now become validated live behavior
4. `docs/prd/subsystems/README.md` if the change affects subsystem navigation
5. `docs/prd/domain/README.md` if the change affects shared vocabulary or boundary definitions
