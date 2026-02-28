# 0135 Newt Timeout Diagnostics

As of this update, the kubeconfig plumbing issue was resolved and the `ops-brain` Newt install reached a later failure point.

## What changed

The `fossorial/newt` release now reaches the cluster and starts installing, but the initial Helm `--wait` timed out with:

- `context deadline exceeded`

That means the problem is no longer:

1. SSH access
2. 1Password credential retrieval
3. kubeconfig binding
4. Helm repo access

It is now in the release readiness path.

## Fix applied

`scripts/2-ops/ops-brain/10-install-newt.sh` now:

1. reads a canonical Helm timeout from `ops/ansible/group_vars/ops_brain.yml`
2. uses `--timeout <value>` explicitly during `helm upgrade --install`
3. prints diagnostics on failure:
   - `kubectl get pods -n newt -o wide`
   - recent namespace events
   - `helm status`

Current default timeout:

- `pangolin_newt_helm_timeout: "10m"`

## Why this matters

This changes the next failure from a generic Helm timeout into something actionable:

1. image pull failure
2. crash loop
3. scheduling issue
4. readiness probe issue
5. chart/value mismatch

## Verification tip

If the next run fails, trust the dumped pod/event/status output before changing architecture or credentials.

At this point, the right question is:

- why the Newt release is not becoming ready

not:

- whether the control-plane plumbing exists
