# 0050 - Secret Sync Validation
Status: ✅ COMPLETE
Date: 2026-02-26
Scope: Rebuild reliability + 1Password ExternalSecret key format validation.

## What happened
- `kubectl` initially failed with `host.docker.internal:* connection refused` due to stale/unset kubeconfig context.
- Cluster/session scripts were updated so `k8s-up` refreshes isolated kubeconfig and verifies API reachability.
- External Secrets sync initially failed due to invalid 1Password reference formats.

## Verification done
- Full nuke/rebuild was run multiple times.
- A/B test compared two formats:
  - A: `remoteRef.key: "test/foo"` -> **success**
  - B: `remoteRef.key: "test"` + `property: "foo"` -> **failure**
- Decoded Kubernetes secret value from successful path: `bar`.

## Final working config
- ExternalSecret uses:
  - `remoteRef.key: "test/foo"`
- File:
  - `/workspaces/rita-v4/manifests/0020-test-secret.yaml`

## Rebuild expectation
- Rebuild should produce synced ExternalSecret and target Kubernetes Secret.
- Validation commands:
```bash
scripts/2-ops/local/rebuild-cluster.sh
kubectl get externalsecret lab-test-sync -n external-secrets
kubectl get secret rita-test-k8s-secret -n external-secrets -o jsonpath='{.data.my-test-value}' | base64 -d; echo
```
- Expected result:
  - `lab-test-sync` READY = `True`
  - decoded value = `bar`
