#!/bin/bash
source /workspaces/rita-v4/scripts/.k8s-env

# Safety Guard
if [[ "$CLUSTER_NAME" != "rita-local" ]]; then
    echo "❌ Rebuild blocked: Cluster is not 'rita-local'."
    exit 1
fi

read -p "⚠️  Confirm full reconstruction of $CLUSTER_NAME? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Aborted."
    exit 0
fi

echo "🗑️  Deleting cluster and local config..."
k3d cluster delete "$CLUSTER_NAME"
rm -f "$KUBECONFIG"

# Execute the master bootstrap
/workspaces/rita-v4/scripts/0-local-setup/02-k8s/01-bootstrap-k8s.sh