#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

runbook_require_cmd curl

PANGOLIN_BIN="${HOME}/.local/bin/pangolin"

if FOUND_BIN="$(runbook_find_pangolin_cli)"; then
  echo "[INFO] Pangolin CLI already installed at $FOUND_BIN"
  "$FOUND_BIN" --help >/dev/null
  echo "[INFO] Your shell PATH does not currently include ~/.local/bin"
  echo "[INFO] Add it with:"
  echo "       export PATH=\"$HOME/.local/bin:\$PATH\""
  echo "[OK] Pangolin CLI is installed and callable by absolute path"
  exit 0
fi

echo "[INFO] Installing Pangolin CLI on Mac host"
curl -fsSL https://static.pangolin.net/get-cli.sh | bash

if FOUND_BIN="$(runbook_find_pangolin_cli)"; then
  "$FOUND_BIN" --help >/dev/null
  echo "[INFO] Pangolin CLI installed at $FOUND_BIN"
  echo "[INFO] Your shell PATH does not currently include ~/.local/bin"
  echo "[INFO] Add it with:"
  echo "       export PATH=\"$HOME/.local/bin:\$PATH\""
  echo "[OK] Pangolin CLI installed and callable by absolute path"
  exit 0
fi

runbook_fail "Pangolin CLI installer completed but the binary was not found in PATH or at $PANGOLIN_BIN"
