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

# Extract a simple top-level YAML key value from a file.
# Supports lines like: key: "value" or key: value
runbook_yaml_get() {
  local file_path="$1"
  local key="$2"
  [ -f "$file_path" ] || return 1
  awk -v k="$key" '
    $0 ~ "^[[:space:]]*"k":[[:space:]]*" {
      sub("^[[:space:]]*"k":[[:space:]]*", "", $0)
      gsub(/^"/, "", $0)
      gsub(/"$/, "", $0)
      gsub(/[[:space:]]+$/, "", $0)
      print $0
      exit
    }
  ' "$file_path"
}
