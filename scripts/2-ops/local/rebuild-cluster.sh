#!/bin/bash
source /workspaces/rita-v4/scripts/.k8s-env

# Guardrail: Hard-coded Name Check
# Prevents the script from running if the environment is pointed at a remote cluster.
if [ "$CLUSTER_NAME" != "rita-local" ]; then
    echo "ERROR: This script is restricted to 'rita-local'."
    echo "Current CLUSTER_NAME: $CLUSTER_NAME"
    exit 1
fi

# Manual Confirmation
echo "WARNING: This will DESTRUCTIVELY delete the cluster: $CLUSTER_NAME"
echo "All local Kubernetes data will be removed."
read -p "Are you sure you want to rebuild $CLUSTER_NAME? (y/N): " confirm

if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "Rebuild cancelled."
    exit 0
fi

echo "Starting cluster reconstruction..."

# 1. Remove the Ghost Cluster
# k3d handles the removal of the underlying Docker containers.
echo "Deleting cluster: $CLUSTER_NAME..."
k3d cluster delete "$CLUSTER_NAME"

# 2. Cleanup Kubeconfig
# Removes the specific config file to prevent context pollution.
echo "Removing isolated kubeconfig..."
rm -f "$KUBECONFIG"

# 3. Trigger Bootstrap
# Calls the primary setup script to recreate the infrastructure.
echo "Triggering bootstrap..."
/workspaces/rita-v4/scripts/0-local-setup/02-k8s/01-bootstrap-k8s.sh

echo "Reconstruction complete. Check status with scripts/1-session/04-k8s-status.sh"