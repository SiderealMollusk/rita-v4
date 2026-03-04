# 0480 - Nextcloud AppAPI / HaRP ExApp Path
Status: ACTIVE
Date: 2026-03-03

## Problem

Nextcloud `Flow` and AI apps like `Local Text to Speech` are not plain top-bar apps.

They are ExApps managed by `AppAPI`, which means:
1. the app package can be enabled in Nextcloud
2. but the actual runtime still needs an AppAPI deploy daemon
3. and the daemon-backed runtime needs public `/exapps/` routing

Current live state:
1. `app_api` is enabled
2. `webhook_listeners` is enabled
3. `flow` is enabled as a Nextcloud app package
4. no AppAPI daemon is registered yet

That is why the App Store shows `Default Deploy daemon is not accessible`.

## Chosen Direction

Use `HaRP` as the AppAPI deploy daemon.

Why:
1. it is the current recommended AppAPI path for newer Nextcloud installs
2. it works with a remote Docker host, which fits this repo better than trying to make k3s/containerd pretend to be a Docker daemon
3. it keeps ExApp runtime concerns separate from the main Nextcloud container

## Repo-Fit Architecture

### Nextcloud
1. stays on the `workload` lane in Kubernetes
2. keeps its current Helm/Flux deployment model

### HaRP
1. runs as a dedicated service reachable from the Nextcloud pod
2. should be treated as a Nextcloud-adjacent integration service, not as a generic platform primitive
3. repo manifests expose it as `nextcloud-appapi-harp.workload.svc.cluster.local:8780`
4. repo manifests expose FRP on node port `30782` for the remote Docker host

### ExApp runtime
1. runs on the `workload` host through Docker
2. is separate from k3s/containerd
3. is appropriate on `workload-node` because these are application workloads, not platform services

### Edge routing
1. Pangolin should continue to front `app.virgil.info`
2. the backend should stop pointing directly at `nextcloud.workload.svc.cluster.local:8080`
3. instead, the backend should point at a cluster-side reverse proxy path split:
4. `/exapps/` -> `HaRP`
5. everything else -> `nextcloud`
6. repo manifests expose that split as service `nextcloud-edge.workload.svc.cluster.local:8080`

## Why The Current Shape Blocks ExApps

The current public route sends all traffic directly to the Nextcloud service.

That works for classic apps, but ExApps need:
1. daemon control traffic
2. public callback traffic under `/exapps/`

Without that path split:
1. Nextcloud can show ExApp UIs in the store
2. but deployment and runtime traffic do not have a valid landing place

## Canonical Operator Flow

1. Run [17-enable-nextcloud-flow.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/17-enable-nextcloud-flow.sh) to install the Nextcloud-side app package and prerequisites.
2. Stand up the HaRP endpoint and remote Docker path.
3. Run [18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh) with the real daemon coordinates.
4. Run [19-deploy-nextcloud-flow-exapp.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/19-deploy-nextcloud-flow-exapp.sh) to deploy Flow through AppAPI.
5. If Flow `1.3.1` crashes on Windmill OSS-only endpoints, run [20-patch-nextcloud-flow-oss.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/20-patch-nextcloud-flow-oss.sh) until the upstream Flow image ships a fix.

## Known Flow Regression

Current live testing on March 3-4, 2026 shows Flow `1.3.1` assumes Windmill endpoints that are not implemented in OSS:
1. `POST /api/users/setpassword`
2. `POST /api/w/nextcloud/workspaces/edit_auto_invite`

Observed effect:
1. the ExApp container is created correctly
2. but startup aborts during `initialize_windmill()`
3. AppAPI then disables the Flow ExApp because the runtime never stabilizes

Current repo stance:
1. keep the AppAPI / HaRP / Docker architecture
2. treat this as an upstream Flow bug, not an installation-architecture failure
3. use the patch runbook above as a temporary workaround

## Required Follow-On Implementation

1. add a cluster-side reverse proxy or ingress for `app.virgil.info` path splitting
2. deploy `HaRP` with a stable shared key and reachable FRP port
3. install Docker plus FRP client on the `workload` host
4. register the daemon in Nextcloud
5. re-deploy `Flow` and validate at least one additional ExApp
