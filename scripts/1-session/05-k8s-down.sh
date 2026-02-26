#!/bin/bash
source $(dirname "$0")/../.k8s-env

echo "🛑 Putting $CLUSTER_NAME to sleep..."

if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    k3d cluster stop "$CLUSTER_NAME"
    echo "✅ Resources reclaimed."
else
    echo "❓ Cluster $CLUSTER_NAME not found."
fi