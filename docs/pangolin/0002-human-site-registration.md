# 0002 - Human Site Registration (Pangolin -> 1Password -> Newt)

Status: Accepted
Validated: 2026-02-28

## Purpose
This is the current human-driven playbook for creating a Pangolin site and getting its credentials into the repo-managed automation flow.

This exists because site creation is still treated as an operator boundary.
The repo automates what happens after the site credentials are known.

## Current Flow
1. Create the site in Pangolin UI at `https://pangolin.virgil.info`.
2. Choose the Kubernetes/Helm installation option.
3. Copy the site name you created in the UI.
4. Copy the rendered Helm install snippet from the Pangolin site creation screen.
5. Run the host-side ingest script to extract endpoint, `id`, and `secret` into 1Password.
6. Run a devcontainer validation script to confirm the note shape and readability.
7. Run the `ops-brain` services phase to install Newt from the validated 1Password item.

## 1Password Contract
For the current `ops-brain` site on `ops-brain`, the expected item is:
1. title: `pangolin_site_ops_brain`
2. category: Secure Note
3. fields:
- `name`: `ops-brain`
- `id`: Pangolin-issued site id
- `secret`: Pangolin-issued site secret

Notes:
1. The endpoint is not copied from the UI into the OP item by hand.
2. The canonical endpoint comes from `ops/network/routes.yml`.
3. The item title is validated against repo vars before use.
4. The host-side ingest script also refuses mismatched site names or endpoints so repo state and Pangolin state do not silently drift.

## Verification Path
1. Ingest the site Helm snippet from the Mac host:
- `scripts/2-ops/host/10-write-ops-brain-pangolin-site-secret.sh`
1. Validate the OP item from the devcontainer:
- `scripts/2-ops/devcontainer/20-validate-ops-brain-pangolin-site.sh`
2. Install Newt after validation:
- `scripts/2-ops/ops-brain/02-services/00-run-all.sh`

## Guardrail
If a site secret is ever exposed in chat or an unsafe place:
1. discard it
2. recreate or rotate the Pangolin site credentials
3. rerun the host-side ingest script with the new Helm snippet
4. rerun the validation script
