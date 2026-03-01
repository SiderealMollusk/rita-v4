# 0310 Blueprint Site Identifier Separated From Newt Id

As of this update, the repo no longer assumes the Pangolin blueprint `site` field can use the Newt credential `id`.

What changed:
1. the canonical OP item contract for `pangolin_site_ops_brain` now includes:
   - `identifier`
2. the host-side Pangolin site ingest script now prompts for and stores that value
3. the devcontainer validator now requires that field
4. the monitoring blueprint now uses a `__SITE_IDENTIFIER__` placeholder
5. the host-side blueprint apply script renders the live site identifier from OP before applying

Why:
1. Pangolin site display name, Pangolin site identifier, and Newt credential id are different concepts
2. the earlier blueprint apply failure:
   - `Site not found: ops-brain in org virgil-labs`
   was consistent with using the wrong `site` value

Operational consequence:
1. rerun the host-side site ingest script once to add `identifier` to the OP item
2. after that, blueprint apply should stop guessing which site token to use
