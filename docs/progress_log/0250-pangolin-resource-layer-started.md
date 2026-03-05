# 0250 Pangolin Resource Layer Started

As of this update, the repo now has a dedicated planning and artifact location for Pangolin-managed resource exposure from the `observatory` site.

## What was added

1. a concrete plan for Pangolin resource management:
   - `/Users/virgil/Dev/rita-v4/docs/plans/0150-pangolin-resource-management-for-observatory.md`
2. a canonical blueprint directory:
   - `/Users/virgil/Dev/rita-v4/ops/pangolin/blueprints/observatory/`
3. an initial draft monitoring blueprint artifact:
   - `monitoring.blueprint.yaml`

## Important scope boundary

Blueprints are now being treated as:
1. the declarative layer for Pangolin resource exposure

Blueprints are explicitly not being treated as:
1. site creation
2. Newt credential issuance
3. initial bootstrap

## Validated basis for this move

This step was justified only after verifying from the Newt pod that:
1. cluster-local service DNS resolves
2. Grafana is reachable
3. Prometheus is reachable

That proof lives in:
1. `/Users/virgil/Dev/rita-v4/docs/progress_log/0240-newt-can-reach-cluster-services.md`

## Next step

1. validate the live Pangolin CLI/apply workflow from the Mac host
2. apply Grafana first
