# 0300 Grafana Public Domain Added To Blueprint

As of this update, the `observatory` monitoring blueprint is no longer missing the required public domain field for HTTP resources.

## What changed

1. the canonical route catalog now includes:
   - `grafana.virgil.info`
2. the `observatory` monitoring blueprint now sets:
   - `full-domain: grafana.virgil.info`

## Why

The live Pangolin CLI rejected the prior draft with:

1. `When protocol is 'http', a 'full-domain' must be provided`

That means the earlier draft was structurally incomplete even though the site target itself was valid.

## Current intended first public resource

1. `grafana.virgil.info`
   - site: `observatory`
   - target: `observatory-kube-prometheus-grafana.monitoring.svc.cluster.local:80`
