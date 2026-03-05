# 0260 Host Blueprint Apply Script Added

As of this update, the repo now has a host-side runbook for applying the canonical `observatory` monitoring blueprint through the Pangolin CLI.

## What was added

1. `/Users/virgil/Dev/rita-v4/scripts/2-ops/host/20-apply-observatory-monitoring-blueprint.sh`

## Scope

This script:
1. runs on the Mac host
2. points at the canonical draft blueprint file
3. applies it with:
   - `pangolin apply blueprint`

This script does not:
1. create the Pangolin site
2. issue Newt credentials
3. log in to Pangolin for you

## Current assumption

The operator has already:
1. installed the Pangolin CLI
2. authenticated it against the working `pangolin-server`

## Next step

1. apply the Grafana-first monitoring blueprint
2. confirm the resulting resource behavior in Pangolin
