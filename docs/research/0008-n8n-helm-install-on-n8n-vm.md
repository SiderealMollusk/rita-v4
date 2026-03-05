# 0008 - n8n Helm Install Research Adapted To n8n VM
Date: 2026-03-05
Status: Active research note

## Scope
Research installation of `n8n` via Helm, link several real examples, and adapt the findings to this repo's current environment (dedicated `n8n-vm` joined to internal k3s cluster).

## Environment assumptions from this repo
1. Dedicated VM exists: `n8n-vm` (`192.168.6.185`) in inventory ([n8n-cluster.ini](/Users/virgil/Dev/rita-v4/ops/ansible/inventory/n8n-cluster.ini)).
2. VM is joined as workload node via scripts `29-33` ([workload README](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/README.md)).
3. Current `n8n` app is plain manifests in `ops/gitops/platform/apps/n8n/` (Deployment + PVC + Service + ExternalSecret) ([kustomization.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/kustomization.yaml)).
4. Current pod placement is pinned to the dedicated node with:
   - `rita.role=workload`
   - `kubernetes.io/hostname=n8n`
   ([n8n-deployment.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/n8n-deployment.yaml)).
5. Current DB target is `platform-postgres.platform.svc.cluster.local` and secrets come from `n8n-secrets` ExternalSecret.

## Online Helm examples (linked)

### Example 1 - 8gears chart (widely used community chart)
Link:
1. https://github.com/8gears/n8n-helm-chart

What it shows:
1. OCI install pattern (`helm install ... oci://8gears.container-registry.com/library/n8n`).
2. Values model maps `main.config` and `main.secret` directly into env vars.
3. Built-in scaling model for worker/webhook with Redis support.

Fit to this repo:
1. Good fit for migration from raw manifests to structured values.
2. Supports the env-var-first style you already use.

### Example 2 - idirouhab chart (queue-first production shape)
Link:
1. https://github.com/idirouhab/n8n-helm-chart

What it shows:
1. OCI chart install with explicit external Postgres + Redis + secret refs.
2. Queue-mode defaults and optional multi-main/webhook processor modes.
3. Example-based install scripts for secrets and values.

Fit to this repo:
1. Useful reference for future high-throughput queue architecture.
2. Less suitable as first migration if you want to keep today's single-main private setup unchanged.

### Example 3 - a5r0n chart (simple OCI install)
Link:
1. https://github.com/a5r0n/n8n-chart

What it shows:
1. Minimal OCI install and simple values file including ingress/postgres knobs.

Fit to this repo:
1. Good for understanding minimal chart shape.
2. Smaller ecosystem footprint than 8gears; treat as secondary reference.

### Example 4 - Flux HelmRelease + OCI reference pattern (GitOps style)
Links:
1. https://fluxcd.io/flux/components/helm/helmreleases/
2. https://fluxcd.io/flux/components/source/ocirepositories/
3. https://fluxcd.io/flux/cheatsheets/oci-artifacts/

What it shows:
1. Recommended modern Flux shape: `OCIRepository` + `HelmRelease chartRef`.
2. Native GitOps reconciliation and upgrade flow.

Fit to this repo:
1. Strong fit because this repo already uses Flux/Kustomize for cluster state.

## Recommendation for this environment

### Recommended path
1. Use `8gears` chart as the primary Helm source.
2. Deploy through Flux (`OCIRepository` + `HelmRelease`) in namespace `platform`.
3. Preserve existing behavior first (single main pod, private ClusterIP, same secrets/DB, same node pinning).
4. Defer queue-mode worker/webhook split to a second phase after baseline stability.

Reasoning:
1. Lowest behavior change from current manifests.
2. Keeps install model consistent with GitOps lane.
3. Leaves room for queue-mode scale-up later without replatforming.

## Adaptation blueprint (this repo)

### 1) Source object for chart
Create an OCI source in `platform` lane for the chosen chart.

### 2) HelmRelease for n8n
Set values to match current deployment contract:
1. image tag pinned to current operational version (`2.7.4`) until intentional upgrade.
2. service type `ClusterIP`.
3. persistence mounted at `/home/node/.n8n`.
4. env values equivalent to current deployment:
   - `DB_TYPE=postgresdb`
   - `DB_POSTGRESDB_HOST=platform-postgres.platform.svc.cluster.local`
   - `DB_POSTGRESDB_PORT=5432`
   - `DB_POSTGRESDB_DATABASE=n8n`
   - `DB_POSTGRESDB_USER=n8n`
   - `N8N_ENCRYPTION_KEY` from existing secret
   - `N8N_RUNNERS_ENABLED=true`
   - `N8N_METRICS=true`
   - `GENERIC_TIMEZONE=America/Los_Angeles`
5. node placement constraints:
   - `nodeSelector.rita.role=workload`
   - `nodeSelector.kubernetes.io/hostname=n8n`

Example Flux shape (illustrative skeleton, adapt to chart schema/version before applying):
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: n8n-chart
  namespace: platform
spec:
  interval: 10m
  url: oci://8gears.container-registry.com/library/n8n
  ref:
    semver: ">=1.0.0 <2.0.0"
  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: n8n
  namespace: platform
spec:
  interval: 10m
  releaseName: n8n
  chartRef:
    kind: OCIRepository
    name: n8n-chart
  values:
    # map these using the chosen chart's README:
    # - image tag pin
    # - postgres host/user/db
    # - encryption key secret reference
    # - nodeSelector (rita.role=workload, kubernetes.io/hostname=n8n)
    # - ClusterIP service
    # - existing PVC n8n-data (or chart-managed PVC)
  valuesFrom: []
```

### 3) Secrets model
Keep existing ExternalSecret item (`n8n-secrets`) and feed Helm values via `valuesFrom` secret references rather than committing secrets in values.

### 4) Health and rollout checks
After reconcile:
1. `kubectl get hr -n platform`
2. `kubectl get pods,svc,pvc -n platform`
3. `kubectl logs -n platform deploy/n8n --tail=200`
4. `kubectl get secret n8n-secrets -n platform`

## Suggested phased migration

### Phase A - parity migration (no feature expansion)
1. Introduce Helm source + HelmRelease while keeping old manifests disabled.
2. Match current behavior exactly (single pod, no queue workers).
3. Verify readiness and DB connectivity.

### Phase B - optional queue mode
1. Add Redis.
2. Enable queue mode per n8n docs.
3. Add worker replicas and optionally dedicated webhook processors.

Reference docs for phase B:
1. queue mode: https://docs.n8n.io/hosting/scaling/queue-mode/
2. supported DB config: https://docs.n8n.io/hosting/configuration/supported-databases-settings/
3. reverse proxy webhook URL: https://docs.n8n.io/hosting/configuration/configuration-examples/webhook-url/

## Practical caveats
1. n8n does not publish an official first-party Helm chart; chart quality/version cadence varies by maintainer.
2. Keep `N8N_ENCRYPTION_KEY` stable across upgrades/redeploys.
3. If you expose n8n later behind proxy, set `WEBHOOK_URL` and `N8N_PROXY_HOPS`.
4. Current bring-up blocker in repo was control-plane reachability, not manifest syntax ([0550](/Users/virgil/Dev/rita-v4/docs/progress_log/0550-n8n-platform-gitops-scaffolded-but-bring-up-blocked.md)).

## Conclusion
For this environment, the most stable path is:
1. Flux-managed Helm (`OCIRepository` + `HelmRelease`)
2. chart choice: `8gears`
3. deployment behavior: parity with existing single-instance private n8n on dedicated `n8n-vm`
4. queue-mode scaling only after baseline passes
