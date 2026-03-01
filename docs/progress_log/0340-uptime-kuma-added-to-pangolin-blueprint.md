# 0340 Uptime Kuma Added To Pangolin Blueprint

As of this update:

1. The `ops-brain` monitoring Pangolin blueprint now includes `uptime.virgil.info`.
2. The target is the in-cluster Kuma service:
   - `ops-brain-kuma-uptime-kuma.monitoring.svc.cluster.local:80`
3. The route catalog now records `uptime.virgil.info` as a Pangolin-routed `ops-brain` resource.

Verification expectation:

1. Re-apply the monitoring blueprint from the Mac host.
2. Confirm Pangolin shows an additional protected public resource for Uptime Kuma.
3. Confirm `https://uptime.virgil.info` serves through Pangolin authentication.
