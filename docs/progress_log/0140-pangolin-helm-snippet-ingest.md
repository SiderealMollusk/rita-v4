# 0140 Pangolin Helm Snippet Ingest

As of this update, the host-side Pangolin site credential flow was tightened around the actual Pangolin UI artifact instead of manual field transcription.

## What changed

`scripts/2-ops/host/10-write-observatory-pangolin-site-secret.sh` now:

1. runs on the Mac host only
2. asks for the Pangolin site name
3. asks for a paste of the Pangolin Helm install snippet
4. extracts:
   - endpoint
   - id
   - secret
5. writes those values into the canonical 1Password item

## Why this is better

Manual field entry was too error-prone:

1. easy to transpose `id`
2. easy to paste the wrong secret
3. easy to silently drift from the repo's canonical endpoint

The Helm snippet already contains the exact auth material Newt will use.

## Guardrails added

The ingest script now fails if:

1. pasted site name does not match the repo-configured site name
2. pasted endpoint does not match `ops/network/routes.yml`
3. the Helm snippet does not contain parsable `endpointKey`, `idKey`, or `secretKey`

## Required operator update

The current operator habit should now be:

1. create or rotate the site in Pangolin
2. copy the displayed Helm snippet
3. run the host-side ingest script
4. run the devcontainer validator
5. only then rerun the Newt install

This reduces manual translation errors between Pangolin UI and 1Password.
