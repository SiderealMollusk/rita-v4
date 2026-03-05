# 0130 Newt Kubeconfig Plumbing Fix

As of this update, the `observatory` services phase reached the Newt Helm install and failed for a specific automation reason, not a topology or credentials reason.

## What was true when this was written

The following parts of the flow were already working:

1. `observatory` SSH + Ansible access
2. k3s on `observatory`
3. Helm on `observatory`
4. Pangolin site credentials readable from 1Password item `pangolin_site_observatory`
5. Newt namespace creation
6. Kubernetes secret creation for Newt credentials
7. Fossorial Helm repo add/update

The failing step was the final Helm release install.

## Root cause

`10-install-newt.sh` was running remote `kubectl` and `helm` commands without explicitly binding the kubeconfig path.

Under automation, that allowed Helm to fall back to the default client target:

- `http://localhost:8080`

That produced:

- `Kubernetes cluster unreachable: Get "http://localhost:8080/version"...`

## Fix applied

`scripts/2-ops/observatory/10-install-newt.sh` now:

1. reads `ansible_user` from `ops/ansible/inventory/observatory.ini`
2. derives:
   - `/home/<ansible_user>/.kube/config`
3. exports that kubeconfig explicitly for every remote Kubernetes-aware command:
   - namespace creation
   - secret creation
   - Helm repo update
   - Helm release install

## Verification tip

If the same class of bug appears again, look for:

1. Helm or kubectl trying `localhost:8080`
2. remote scripts assuming login-shell kubeconfig state
3. ad-hoc shell steps that do not pass `KUBECONFIG` or `--kubeconfig`

That is the signal that the issue is command plumbing, not cluster health.
