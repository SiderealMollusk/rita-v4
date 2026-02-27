#!/bin/bash
set -euo pipefail
source $(dirname "$0")/../.k8s-env

echo "🌙 Waking up $CLUSTER_NAME..."

# Ensure the bridge is open (The script we created earlier)
source $(dirname "$0")/02-docker-check.sh

# Start containers if they are stopped (or create if missing)
if k3d cluster list "$CLUSTER_NAME" --no-headers >/dev/null 2>&1; then
    k3d cluster start "$CLUSTER_NAME"
else
    echo "🧱 Cluster $CLUSTER_NAME not found. Creating..."
    k3d cluster create "$CLUSTER_NAME" --wait
fi

# Refresh the local kubeconfig reference
mkdir -p "$HOME/.kube"
k3d kubeconfig merge "$CLUSTER_NAME" --output "$KUBECONFIG"
export KUBECONFIG

# Confirm the API endpoint is reachable before returning control
echo "🔎 Verifying Kubernetes API..."
for i in 1 2 3 4 5; do
    if kubectl version --request-timeout=10s >/dev/null 2>&1; then
        break
    fi
    if [ "$i" -eq 5 ]; then
        echo "❌ Kubernetes API is not reachable after kubeconfig refresh."
        exit 1
    fi
    sleep 2
done

echo "✅ $CLUSTER_NAME is online."
