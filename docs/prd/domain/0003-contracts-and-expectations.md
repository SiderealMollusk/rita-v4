# 0003 - Contracts And Expectations

This note captures the first useful contracts between the major parts of the system.

They are intentionally high-level. The goal is to anchor future implementation, not to finalize APIs.

## Shape Contract

The product should continue to respect this high-level shape:
1. `Hive <-> contributor server <-> contributor page`
2. `Hive <-> Nextcloud`
3. `Nextcloud <-> contributor`
4. `Nextcloud <-> AI pilots`

This should be read as a product and boundary contract, not as a final deployment topology.

## Vocabulary Contract

Future work should avoid collapsing these terms:
1. `Soul`
2. `Caste`
3. `Character`
4. `Pilot`
5. `Agent Instance`

Expected distinction:
1. `Soul` is continuity
2. `Caste` is role template
3. `Character` is the recognizable worker identity
4. `Pilot` is the active intelligence
5. `Agent Instance` is the live embodiment

## Memory Contract

The system should distinguish:
1. collaborative memory
2. execution memory

Collaborative memory is expected to live primarily in Nextcloud-like surfaces.

Execution memory is expected to remain outside Nextcloud and to support:
1. retries
2. leases
3. in-flight work state
4. exact sequencing
5. run metadata
6. tracing and accountability

## Work Visibility Contract

Meaningful work should be visible in the front office.

That means:
1. agents should leave socially legible traces
2. human contributors should be able to understand movement without opening machine internals
3. backend rigor should not eliminate visible paperwork-like behavior

## Contributor Contract

The product is currently designed around trusted contributors, not hostile internal actors.

That means:
1. visibility, attribution, and social accountability matter more than pretend zero-trust isolation
2. contributor-supplied compute is expected
3. contributor-supplied pilots may also be expected
4. privacy grades are still meaningful, but should be treated as workload-handling constraints rather than a total adversarial security model

## Compute Contract

The mana server is expected to absorb most heavyweight compute-serving concerns.

That includes:
1. model serving
2. routing and translation
3. budget visibility
4. contribution-oriented compute accountability

The Hive should not grow into an ad hoc model-serving appliance.

## Workspace Contract

Nextcloud should remain the front office and collaborative memory layer.

That means:
1. humans should be able to direct and inspect work there
2. pilots should be able to consume and update relevant workspace state
3. the product should resist turning Nextcloud into the whole backend

## Indexing And Retrieval Contract

An optional vector/index layer is expected.

Some amount of compute should be reserved for `Hive maintenance`, meaning:
1. evaluating what should be indexed
2. preparing focused context
3. revising memory representations over time

This is expected to stay elementary for a while and may become arbitrarily sophisticated later.

## Open Questions

1. whether `Character` should formally include policy overrides in the product language
2. whether a separate `Mandate` concept is needed between team intent and task execution
3. how much of pilot behavior should remain contributor-configurable versus caste-driven
