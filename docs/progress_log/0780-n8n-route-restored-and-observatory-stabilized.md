# 0780 n8n Route Restored and Observatory Stabilized

Freshness stamp:
- 2026-03-05 16:55 PST (background agent)

## Summary
`n8n` was confirmed healthy in-cluster and restored at the public route after re-applying canonical Pangolin resource wiring. Observatory monitoring services remain healthy and externally reachable with the expected app-level redirects/setup flow.

## Work Completed
1. Verified `n8n` workload state in `platform` namespace:
   - `pod/n8n-*` running
   - `service/n8n` present on `5678/TCP`
   - `pvc/n8n-data` bound
2. Verified Pangolin site and Newt connector health:
   - `scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh` passed
3. Re-applied canonical n8n blueprint:
   - `scripts/2-ops/host/31-apply-n8n-blueprint.sh`
4. Confirmed public route behavior:
   - `https://n8n.virgil.info` now returns `302` to Pangolin auth (no longer `404`)
5. Checked n8n app logs:
   - n8n reports ready and advertises `https://n8n.virgil.info`

## Current State
1. Cluster control plane still runs on `monitoring` (`control-plane` role).
2. n8n is up and externally reachable through Pangolin auth.
3. Observatory monitoring stack remains running and externally routed.

## Notes
1. Current topology remains hack-friendly and operational; no CP migration was executed in this change.
