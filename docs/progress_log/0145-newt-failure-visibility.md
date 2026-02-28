# 0145 Newt Failure Visibility

As of this update, the `ops-brain` Newt install path has better built-in diagnostics for runtime failures.

## Why this changed

The earlier diagnostics were enough to distinguish:

1. kubeconfig plumbing failures
2. Helm timeout failures

But they were still too weak for fast root-cause isolation once the pod actually started and crashed.

The decisive signal came from manual log inspection:

- `Secret is incorrect`

That signal should have been part of the runbook automatically.

## What was added

When `scripts/2-ops/ops-brain/10-install-newt.sh` fails or times out, it now also prints:

1. secret data structure for `newt-cred`
2. `kubectl describe deployment ...`
3. `kubectl logs deployment/... --tail=200`
4. `kubectl describe pod ...`

## Why this matters

The Newt install path can now surface the actual runtime failure in one run:

1. bad credentials
2. probe failures
3. image issues
4. chart/value mismatch
5. deployment wiring problems

That reduces the need for follow-up ad-hoc SSH debugging after a failed run.
