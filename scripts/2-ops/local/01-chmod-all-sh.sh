#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

find "$REPO_ROOT/scripts" -type f -name "*.sh" -exec chmod +x {} +
echo "[OK] Executable bit refreshed for shell scripts under $REPO_ROOT/scripts"
