#!/bin/bash

# 1. Environment Setup
BASE_DIR="/workspaces/rita-v4/scripts"
if [ -f "$BASE_DIR/.k8s-env" ]; then
    source "$BASE_DIR/.k8s-env"
else
    echo "Error: Configuration not found at $BASE_DIR/.k8s-env"
    exit 1
fi

# Colors for scannability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📊 Checking Lab Status: $CLUSTER_NAME${NC}"

# 2. Docker Check
if docker ps > /dev/null 2>&1; then
    echo -e "  [${GREEN}OK${NC}] Docker Engine Reachable"
else
    echo -e "  [${RED}!!${NC}] Docker Engine Unreachable"
    exit 1
fi

# 3. Cluster State (Pattern Matching)
CLUSTER_INFO=$(k3d cluster list "$CLUSTER_NAME" --no-headers 2>/dev/null)

if [[ -z "$CLUSTER_INFO" ]]; then
    echo -e "  [${RED}!!${NC}] k3d Cluster: NOT FOUND"
elif [[ "$CLUSTER_INFO" == *"1/1"* ]]; then
    echo -e "  [${GREEN}OK${NC}] k3d Cluster: Running"
else
    echo -e "  [${RED}!!${NC}] k3d Cluster: Incomplete/Stopped"
    echo "      $CLUSTER_INFO"
fi

# 4. External Secrets Operator Health
# Checks if all three core pods are in Running state
ESO_COUNT=$(kubectl get pods -n "$K8S_NAMESPACE" --no-headers 2>/dev/null | grep "Running" | wc -l)
if [ "$ESO_COUNT" -eq 3 ]; then
    echo -e "  [${GREEN}OK${NC}] External Secrets: Healthy (3/3 pods)"
else
    echo -e "  [${YELLOW}..${NC}] External Secrets: Initializing ($ESO_COUNT/3 pods)"
fi

# 5. Kubeconfig Context
if [[ "$KUBECONFIG" == *"$CLUSTER_NAME"* ]]; then
    echo -e "  [${GREEN}OK${NC}] Kubeconfig: Isolated"
else
    echo -e "  [${YELLOW}??${NC}] Kubeconfig: Default context in use"
fi

echo -e "${YELLOW}--- Check Complete ---${NC}"