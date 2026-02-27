#!/bin/bash
set -e
source /workspaces/rita-v4/scripts/.k8s-env

echo "🏗️  Starting Master Bootstrap for $CLUSTER_NAME..."

# 1. Create or Start Cluster
if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "Creating new k3d cluster..."
    k3d cluster create "$CLUSTER_NAME" --wait
else
    echo "Cluster $CLUSTER_NAME already exists. Ensuring it is started..."
    k3d cluster start "$CLUSTER_NAME"
fi

# 2. Setup Kubeconfig Context
k3d kubeconfig merge "$CLUSTER_NAME" --output "$KUBECONFIG"

# 3. Create Infrastructure Namespace
echo "Ensuring namespace '$K8S_NAMESPACE' exists..."
kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 4. Inject 1Password Token (The Secret Handshake)
if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
    echo "🔑 Injecting 1Password token from host environment..."
    kubectl create secret generic op-token \
      --namespace "$K8S_NAMESPACE" \
      --from-literal=token="$OP_SERVICE_ACCOUNT_TOKEN" \
      --dry-run=client -o yaml | kubectl apply -f -
else
    echo "❌ ERROR: OP_SERVICE_ACCOUNT_TOKEN not found."
    exit 1
fi

# 5. Install External Secrets Operator (ESO)
echo "📦 Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace "$K8S_NAMESPACE" \
    --set installCRDs=true \
    --wait

# 6. The "Waiting Room" (Crucial for Local K8s)
echo "⏳ Waiting for CRDs to register and Webhooks to warm up..."
kubectl wait --for condition=established --timeout=60s crd/secretstores.external-secrets.io
kubectl wait --for condition=established --timeout=60s crd/externalsecrets.external-secrets.io

# Force a client-side cache refresh
kubectl api-resources > /dev/null


# 7. Render 1Password SecretStore manifest with dynamic vault ID
LABRC="/workspaces/rita-v4/.labrc"
TEMPLATE="/workspaces/rita-v4/manifests/0010-onepassword-store.yaml.tmpl"
OUTPUT="/workspaces/rita-v4/manifests/0010-onepassword-store.yaml"
if [ -f "$TEMPLATE" ]; then
    if grep -q OP_VAULT_ID "$LABRC"; then
        source "$LABRC"
        if [ -n "$OP_VAULT_ID" ]; then
            sed "s|{{OP_VAULT_ID}}|$OP_VAULT_ID|g" "$TEMPLATE" > "$OUTPUT"
            echo "✅ Rendered $OUTPUT with OP_VAULT_ID=$OP_VAULT_ID"
        else
            echo "❌ OP_VAULT_ID is empty in $LABRC."
            exit 1
        fi
    else
        echo "❌ OP_VAULT_ID not found in $LABRC."
        exit 1
    fi
fi

# 8. Apply Blueprints with a Smart Retry
if [ -d "/workspaces/rita-v4/manifests" ]; then
        echo "📄 Applying manifests from /workspaces/rita-v4/manifests/..."
        MAX_RETRIES=5
        RETRY_COUNT=0
        until kubectl apply -f /workspaces/rita-v4/manifests/ || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
                RETRY_COUNT=$((RETRY_COUNT + 1))
                echo "⚠️  API not quite ready (Attempt $RETRY_COUNT/$MAX_RETRIES). Retrying in 5s..."
                sleep 5
        done
else
        echo "⚠️  Warning: Manifests directory not found."
fi

echo "✅ Master Bootstrap Complete."