# Platform Requirement 0005

## Runbooks And Operator Boundaries

The platform should not depend on remembered shell sequences.

Runbooks exist to consume canonical truth and turn it into repeatable operations.

## Operator Boundary Model

### Repo-Managed Truth

Stable platform facts live in:

- inventory
- `host_vars`
- `group_vars`
- GitOps manifests
- route catalog
- documented secret contracts

### Wrapper Consumption

Runbooks and wrappers should consume that truth.

They should not force the operator to remember:

- cluster kubeconfig exports
- vault IDs
- hostnames
- stable item names

### `.labrc` And `.envrc`

`.labrc` is the preferred home for operator-local non-secret config.
`.envrc` is the preferred repo-managed loader for that config.

Host-side scripts should source shared helpers that ultimately derive their context from these files instead of requiring repeated manual exports.

## Desired Operator Experience

The operator should be able to:

- run short named scripts
- understand what lane they are acting on
- trust those scripts to pull the right config from canonical sources

The operator should not need to memorize hidden state.
