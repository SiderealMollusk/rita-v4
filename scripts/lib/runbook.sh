#!/bin/bash

set -euo pipefail

runbook_fail() {
  echo "[FAIL] $*"
  exit 1
}

runbook_require_no_args() {
  if [ "$#" -ne 0 ]; then
    runbook_fail "This runbook script takes no arguments."
  fi
}

runbook_detect_repo_root() {
  if [ -d /workspaces/rita-v4 ]; then
    echo "/workspaces/rita-v4"
    return
  fi
  if [ -d /Users/virgil/Dev/rita-v4 ]; then
    echo "/Users/virgil/Dev/rita-v4"
    return
  fi
  runbook_fail "Could not locate repo root."
}

runbook_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || runbook_fail "missing command: $1"
}

runbook_require_env() {
  local var_name="$1"
  local hint="${2:-}"
  if [ -z "${!var_name:-}" ]; then
    echo "[FAIL] ${var_name} is not set in this shell."
    if [ -n "$hint" ]; then
      echo "[INFO] ${hint}"
    fi
    exit 1
  fi
}

