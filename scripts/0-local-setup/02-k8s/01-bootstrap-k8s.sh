#!/bin/bash
set -e
source $(dirname "$0")/../../.k8s-env

echo "🏗️  Bootstrapping Cluster: $CLUSTER_NAME"

if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
    k3d cluster create "$CLUSTER_NAME" --wait
else
    echo "✅ Cluster $CLUSTER_NAME already exists."
fi

# Point kubectl to this specific cluster's config file
k3d kubeconfig merge "$CLUSTER_NAME" --output "$KUBECONFIG"

# Install the Secret Abstraction Layer
helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace "$K8S_NAMESPACE" --create-namespace --set installCRDs=true

echo "✅ Bootstrap Complete for $CLUSTER_NAME"