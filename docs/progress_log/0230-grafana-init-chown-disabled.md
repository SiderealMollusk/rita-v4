# 0230 Grafana Init Chown Disabled

As of this update, the `observatory` monitoring stack had a concrete Grafana rollout failure on the persistent volume.

## Root cause

The new Grafana pod failed in the `init-chown-data` init container with:

1. `chown: /var/lib/grafana/pdf: Permission denied`
2. `chown: /var/lib/grafana/png: Permission denied`
3. `chown: /var/lib/grafana/csv: Permission denied`

This was not a total Grafana outage. The older Grafana pod was still healthy and serving, while the new rollout pod was blocked in init.

## Fix

The canonical `kube-prometheus-stack` values now disable:

1. `grafana.initChownData`

## Why this is the right first-pass fix

1. the existing Grafana PVC is already usable by the running pod
2. the failing behavior is the recursive ownership rewrite, not Grafana itself
3. this keeps the local-persistence model intact without inventing a more complex storage workaround

## Recovery path

After applying the updated values, rerun the monitoring install script so Helm rolls Grafana with the new setting.
