#!/bin/bash
source $(dirname "$0")/../.k8s-env

echo "🌙 Waking up $CLUSTER_NAME..."

# Ensure the bridge is open (The script we created earlier)
source $(dirname "$0")/02-docker-check.sh

# Start containers if they are stopped
k3d cluster start "$CLUSTER_NAME"

# Refresh the local kubeconfig reference
k3d kubeconfig merge "$CLUSTER_NAME" --output "$KUBECONFIG"

echo "✅ $CLUSTER_NAME is online."