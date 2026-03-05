# 0160 OP Reveal Secret Fix

As of this update, the `observatory` Newt install failure was traced to 1Password CLI secret retrieval, not Pangolin auth or Kubernetes wiring.

## Root cause

The `secret` field in the 1Password item was stored as a concealed field.

The automation was reading it with:

- `op item get ... --fields label='secret'`

without:

- `--reveal`

That caused 1Password to return its placeholder text instead of the real secret value.

The Kubernetes secret therefore contained a string like:

- `[use 'op item get ... --reveal' to reveal]`

instead of the real Pangolin site secret.

## What changed

Updated:

1. `scripts/2-ops/observatory/10-install-newt.sh`
2. `scripts/2-ops/devcontainer/20-validate-observatory-pangolin-site.sh`

Both now use:

- `op item get ... --reveal --fields label='secret'`

They also explicitly fail if a concealed-field placeholder is returned.

## Why this matters

This bug could masquerade as:

1. bad Pangolin credentials
2. site registration mismatch
3. Newt auth protocol failure

But the actual problem was simpler:

- the secret was never actually revealed from 1Password

## Practical reading rule

If a 1Password field is stored as concealed data and the runtime needs the literal value, the retrieval path must use `--reveal`.
