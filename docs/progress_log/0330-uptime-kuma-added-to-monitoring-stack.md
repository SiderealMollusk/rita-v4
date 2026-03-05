# 0330 Uptime Kuma Added To Monitoring Stack

As of this update, `observatory` monitoring deployment now includes Uptime Kuma as part of the standard monitoring service lane.

What changed:
1. the `observatory` monitoring install script now deploys:
   - `uptime-kuma`
2. the monitoring verify script now checks:
   - Helm release presence for `uptime-kuma`
   - a port-forward command for Kuma
3. canonical Kuma Helm values now live at:
   - `/Users/virgil/Dev/rita-v4/ops/helm/monitoring/uptime-kuma.values.yaml`
4. canonical expected monitor inventory now lives at:
   - `/Users/virgil/Dev/rita-v4/ops/monitoring/kuma/monitors.yaml`

Important boundary:
1. Kuma deployment is part of the cluster Helm layer
2. Kuma monitor definitions are still a separate seeded layer, not embedded into the chart
