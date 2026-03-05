# 0350 Kuma Deployed And Awaiting Bootstrap

As of this update:

1. `observatory` monitoring stack is up after recovery from an unexpected power loss.
2. The following releases are deployed on `observatory`:
   - `observatory-kube-prometheus`
   - `observatory-loki`
   - `observatory-promtail`
   - `observatory-kuma`
3. Pangolin public resources exist and are protected for:
   - `grafana.virgil.info`
   - `prometheus.virgil.info`
   - `alertmanager.virgil.info`
   - `uptime.virgil.info`
4. `Uptime Kuma` is reachable as a deployed service in-cluster at:
   - `observatory-kuma-uptime-kuma.monitoring.svc.cluster.local:80`

Current unresolved boundary:

1. `Uptime Kuma` is presenting a first-run application bootstrap flow.
2. That means Kubernetes/Helm deployment succeeded, but the app still requires initial setup state.
3. This should be treated as an application bootstrap concern, not a cluster deployment failure.

Operational note:

1. Some helper output in the `/workspaces/rita-v4` tree remains stale relative to `/Users/virgil/Dev/rita-v4`.
2. The clearest example is the old hardcoded Kuma service name in verification output.
3. Live cluster truth showed the correct service:
   - `observatory-kuma-uptime-kuma`

Verification cues that were true at this point:

1. Monitoring namespace pods were healthy after restart.
2. Promtail was actively tailing logs.
3. Pangolin resource pages showed protected monitoring resources.
4. `Uptime Kuma` could be reached far enough to display its setup/database prompt.

Next step after this note:

1. Decide which part of Kuma bootstrap is:
   - one-time manual app initialization
   - declarative chart/config state
   - later seeded monitor inventory
