# 0370 Kuma Seeder Conditions Fix

As of this update, the Uptime Kuma monitor seeding script was reaching Kuma, authenticating correctly, parsing the canonical Pangolin monitoring blueprint, and then failing on monitor creation.

The concrete failure was:

- `SQLITE_CONSTRAINT: NOT NULL constraint failed: monitor.conditions`

What this means:

1. the SSH-backed Kuma tunnel was working
2. the Kuma admin credentials in 1Password were working
3. blueprint parsing was working
4. the remaining bug was the monitor creation payload, not the overall seeding design

The fix:

- update [`30-seed-kuma-monitors.sh`](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/30-seed-kuma-monitors.sh) so new monitor creation injects an explicit empty `conditions` array before calling the Kuma API
- keep the blueprint as the canonical source of exposed endpoints

Operational note:

- if monitor seeding fails again, inspect the Python traceback first
- the likely remaining failure mode is API/client contract drift, not blueprint parsing or access boundary issues
