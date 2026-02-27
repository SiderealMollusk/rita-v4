#!/bin/bash
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "[FAIL] This runbook script takes no arguments."
  echo "Use: $(basename "$0")"
  exit 1
fi

if [ -d /workspaces/rita-v4 ]; then
  REPO_ROOT="/workspaces/rita-v4"
elif [ -d /Users/virgil/Dev/rita-v4 ]; then
  REPO_ROOT="/Users/virgil/Dev/rita-v4"
else
  echo "[FAIL] Could not locate repo root."
  exit 1
fi

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"

echo "[INFO] running rollback on VPS: pangolin down"
ansible -i "$INV" vps -b -m shell -a "pangolin down"
echo "[OK] rollback complete"
