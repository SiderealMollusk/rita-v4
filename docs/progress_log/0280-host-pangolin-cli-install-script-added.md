# 0280 Host Pangolin CLI Install Script Added

As of this update, the host/operator lane now includes an explicit Pangolin CLI install step.

## What was added

1. `/Users/virgil/Dev/rita-v4/scripts/2-ops/host/11-install-pangolin-cli.sh`

## Why it belongs in the host lane

1. the blueprint file itself is non-secret
2. the sensitive boundary is the Pangolin CLI auth/session used to mutate Pangolin state
3. that operator privilege lives on the Mac host, not in the devcontainer

## Operational effect

The host lane now has a cleaner sequence:

1. install Pangolin CLI
2. create site in Pangolin
3. ingest site credentials into 1Password
4. apply Pangolin blueprints from the host
