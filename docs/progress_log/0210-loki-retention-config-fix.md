# 0210 Loki Retention Config Fix

As of this update, the `observatory` monitoring stack had a concrete Loki config error, not a generic startup failure.

## Root cause

Loki was configured with retention enabled, but the chart values did not set:

1. `compactor.delete_request_store`

Loki rejected the config with:

1. `invalid compactor config: compactor.delete-request-store should be configured when retention is enabled`

## Fix

The canonical Loki values file now sets:

1. `compactor.delete_request_store: filesystem`

This matches the current local-filesystem, single-binary deployment shape.

## Operational implication

If Loki had already been installed with the broken config, the fastest recovery path is:

1. uninstall the `observatory-loki` release
2. rerun the monitoring install script

Treat the values file as more authoritative than this note if the chart behavior changes later.
