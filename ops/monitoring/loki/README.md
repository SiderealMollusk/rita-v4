# Loki Stream Contract

This directory defines the log-stream source-of-truth contract for the current cluster.

Files:
1. `stream-contract.json`
- required stream namespaces
- required node names
- required job-pattern families
- known/allowed missing-pod patterns for noisy control pods that do not consistently produce log streams

Validation scripts:
1. `/Users/virgil/Dev/rita-v4/scripts/2-ops/host/35-catalog-monitoring-streams.sh`
2. `/Users/virgil/Dev/rita-v4/scripts/2-ops/host/36-verify-monitoring-streams.sh`
3. `/Users/virgil/Dev/rita-v4/scripts/2-ops/host/37-establish-monitoring-streams.sh`
