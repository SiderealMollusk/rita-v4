# 0380 Kuma Seeding Script Disabled

As of this update, the host-side Uptime Kuma seeding script is intentionally disabled.

Affected file:

- [/Users/virgil/Dev/rita-v4/scripts/2-ops/host/30-seed-kuma-monitors.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/30-seed-kuma-monitors.sh)

Reason:

1. the current design still depends on an SSH-backed local port-forward to reach Kuma's API
2. that path is proving unreliable in practice
3. the result is not a stable or trustworthy automation boundary

Observed failure mode:

- repeated inability to bind the local tunnel port
- earlier API payload issues were also encountered before that

Current stance:

1. treat Kuma monitor seeding automation as failed
2. do not rely on the current script
3. if monitor seeding is needed immediately, do it manually in the Kuma UI
4. if automation is revisited later, it should use a different integration approach rather than more local port-forward orchestration

This note is the current freshness anchor for Kuma seeding status.
