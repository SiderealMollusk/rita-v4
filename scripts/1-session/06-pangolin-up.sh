#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ "$#" -ne 0 ]; then
  echo "[FAIL] This runbook script takes no arguments."
  echo "Use: $(basename "$0")"
  exit 1
fi

cd "$REPO_ROOT"
exec "$REPO_ROOT/scripts/2-ops/vps/07-pangolin-deploy.sh"
