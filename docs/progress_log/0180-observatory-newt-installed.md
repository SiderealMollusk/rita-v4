# 0180 Observatory Newt Installed

As of this update, `observatory` successfully installed and deployed `newt` into the local k3s cluster.

## What was validated

1. Pangolin site credentials were ingested from the Pangolin Helm snippet into 1Password
2. The canonical 1Password item is now:
   - `pangolin_site_observatory`
3. The devcontainer validator passed against that item
4. The `observatory` services phase completed `10-install-newt.sh`
5. Helm release status reached:
   - `deployed`

## Root cause chain that was resolved

The Newt install path failed through several distinct layers before succeeding:

1. kubeconfig plumbing was missing in remote Helm/kubectl commands
2. Helm release state could become stuck in `pending-upgrade`
3. 1Password concealed fields were being read without `--reveal`
4. that caused Kubernetes to receive a placeholder string instead of the real secret

After those fixes, the same runbook path completed successfully.

## Canonical state now

1. Pangolin site identity:
   - `observatory`
2. 1Password item:
   - `pangolin_site_observatory`
3. k3s namespace:
   - `newt`
4. Helm release:
   - `observatory-newt`

## Operational note

There is still path drift between:

1. `/Users/virgil/Dev/rita-v4`
2. `/workspaces/rita-v4`

The successful run confirms the active logic is correct, but some cosmetic inventory warning fixes may still only exist in one path copy until the trees are fully aligned.

## Next step

Build the monitoring stack runbooks:

1. `11-install-monitoring-stack.sh`
2. `12-verify-monitoring-stack.sh`
